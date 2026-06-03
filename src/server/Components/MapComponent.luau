local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lists = ReplicatedStorage.Shared.Lists

local DifficultEnum = require(ReplicatedStorage.Shared.Enums.DifficultEnum)
local CurrentMapConfig = require(ReplicatedStorage.Shared.Lists.CurrentMapConfig)
local DebugServices = require(ReplicatedStorage.Shared.Utils.DebugServices)
local Modux = require(game.ReplicatedStorage.Shared.Modux)
local BooksTypes = require(ReplicatedStorage.Shared.Types.BooksTypes)

type Book = BooksTypes.Books

local RandomGenerator = Random.new()
local STACK_CELL_SIZE = 3
local STACK_CHANCE = 0.55
local MAX_STACK_HEIGHT = 8
local STACK_HEIGHT_PADDING = 0.08
local STACK_OFFSET_JITTER = 0.45

local MapComponent = Modux.Component("MapComponent")
    :Tag("Map")
    :ClassName("Instance")
    :AttributeDefaults({
        Difficulty = "Hard",
        TimeLimit = 0,
        MinBook = 100,
    })

local function GetValidSpawnsAreas(Map: Instance): {BasePart} | nil
    local booksSpawns = Map:FindFirstChild("SpawnAreas")
    if not booksSpawns then
        DebugServices:Panic(script.Name, "SpawnAreas folder not found.")
        return
    end

    local Areas = {}
    for _, descentant in booksSpawns:GetDescendants() do
        if descentant:IsA("BasePart") then
            table.insert(Areas, descentant)
        end
    end

    return Areas
end

local function Shuffle<T>(list: {T}): {T}
    local shuffled = table.clone(list)

    for index = #shuffled, 2, -1 do
        local randomIndex = RandomGenerator:NextInteger(1, index)
        shuffled[index], shuffled[randomIndex] = shuffled[randomIndex], shuffled[index]
    end

    return shuffled
end

local function CopyBook(book: Book): Book
    local copy = {}

    for key, value in book do
        copy[key] = value
    end

    return copy :: Book
end

local function GetRandomLocalPointInArea(area: BasePart): Vector3
    local size = area.Size

    return Vector3.new(
        RandomGenerator:NextNumber(-size.X / 2, size.X / 2),
        size.Y / 2,
        RandomGenerator:NextNumber(-size.Z / 2, size.Z /2)
    )
end

local function Quantize(value: number): number
    return math.floor(value / STACK_CELL_SIZE + 0.5) * STACK_CELL_SIZE
end

local function GetAreaStackKey(area: BasePart, localPoint: Vector3): string
    return `{area:GetFullName()}:{Quantize(localPoint.X)}:{Quantize(localPoint.Z)}`
end

local function GetRandomBookRotation(): CFrame
    local lyingAngle = math.rad(90 + RandomGenerator:NextNumber(-18, 18))
    local yaw = math.rad(RandomGenerator:NextNumber(0, 360))
    local roll = math.rad(RandomGenerator:NextNumber(-35, 35))

    return CFrame.Angles(lyingAngle, yaw, roll)
end

local function GetBookStackHeight(book: Model): number
    local _, size = book:GetBoundingBox()
    return math.max(math.min(size.X, size.Y, size.Z), 0.15)
end

local function CreateSpawnStack(area: BasePart)
    local localPoint = GetRandomLocalPointInArea(area)

    return {
        Area = area,
        LocalPoint = localPoint,
        Key = GetAreaStackKey(area, localPoint),
        Count = 0,
        Height = 0,
    }
end

local function SelectSpawnStack(area: BasePart, stacksByKey: {[string]: any}, stackList: {any})
    local validStacks = {}

    for _, stack in stackList do
        if stack.Area == area and stack.Count < MAX_STACK_HEIGHT then
            table.insert(validStacks, stack)
        end
    end

    if #validStacks > 0 and RandomGenerator:NextNumber() <= STACK_CHANCE then
        return validStacks[RandomGenerator:NextInteger(1, #validStacks)]
    end

    local stack = CreateSpawnStack(area)
    local existingStack = stacksByKey[stack.Key]

    if existingStack then
        return existingStack
    end

    stacksByKey[stack.Key] = stack
    table.insert(stackList, stack)

    return stack
end

local function GetBookStackCFrame(book: Model, stack: any): CFrame
    local jitter = Vector3.new(
        RandomGenerator:NextNumber(-STACK_OFFSET_JITTER, STACK_OFFSET_JITTER),
        0,
        RandomGenerator:NextNumber(-STACK_OFFSET_JITTER, STACK_OFFSET_JITTER)
    )

    local bookHeight = GetBookStackHeight(book)
    local localPoint = stack.LocalPoint + jitter + Vector3.new(0, stack.Height + (bookHeight / 2), 0)
    local spawnCFrame = stack.Area.CFrame * CFrame.new(localPoint)

    stack.Count += 1
    stack.Height += bookHeight + STACK_HEIGHT_PADDING

    return spawnCFrame * GetRandomBookRotation()
end

function MapComponent:CreateBook(bookInfo: Book): Model?
    local Assets = ReplicatedStorage:FindFirstChild("Assets")
    if not Assets then
        DebugServices:Panic(script.Name, "ReplicatedStorage.Assets not found.")
        return nil
    end

    local ModelTemplates = Assets:FindFirstChild("ModelTemplates")
    if not ModelTemplates then
        DebugServices:Panic(script.Name, "Assets.ModelTemplates not found.")
        return nil
    end

    local BooksTemplates = ModelTemplates:FindFirstChild("Books")
    if not BooksTemplates then
        DebugServices:Panic(script.Name, "Assets.ModelTemplates.Books not found.")
        return nil
    end

    local BookTemplate = BooksTemplates:FindFirstChild("Book")
    if not BookTemplate or not BookTemplate:IsA("Model") then
        DebugServices:Panic(script.Name, "Book template not found or is not a Model.")
        return nil
    end

    local Book = BookTemplate:Clone()
    Book.Name = tostring(HttpService:GenerateGUID(false))
    Book:SetAttribute("BookId", bookInfo.Id)
    Book:SetAttribute("Title", bookInfo.Title)
    Book:SetAttribute("Theme", bookInfo.Theme)
    Book:SetAttribute("Chapter", bookInfo.Chapter)
    Book:SetAttribute("TotalChapters", bookInfo.TotalChapters)

    return Book
end

function MapComponent:BuildBookPlan(totalBooks: number): {Book}
    local plan = {}
    local bookThemesFolder = Lists:FindFirstChild("BooksThemesLists")

    if not bookThemesFolder then
        DebugServices:Panic(script.Name, "BooksThemesLists folder not found.")
        return plan
    end

    local themeModules = {}
    for _, child in bookThemesFolder:GetChildren() do
        if child:IsA("ModuleScript") then
            table.insert(themeModules, child)
        end
    end

    table.sort(themeModules, function(left, right)
        return left.Name < right.Name
    end)

    local TotalBookThemes: number = #themeModules
    if TotalBookThemes <= 0 then
        DebugServices:Panic(script.Name, "No book theme lists found.")
        return plan
    end

    local baseAmount = math.floor(totalBooks / TotalBookThemes)
    local remainder = totalBooks % TotalBookThemes

    for themeIndex, themeModule in themeModules do
        local books = require(themeModule) :: {Book}
        local booksAmount = baseAmount

        if themeIndex <= remainder then
            booksAmount += 1
        end

        if #books <= 0 then
            DebugServices:Panic(script.Name, `Book list {themeModule.Name} is empty.`)
            continue
        end

        local shuffledBooks = Shuffle(books)

        for bookIndex = 1, booksAmount do
            local selectedBook = shuffledBooks[((bookIndex - 1) % #shuffledBooks) + 1]
            table.insert(plan, CopyBook(selectedBook))
        end
    end

    return Shuffle(plan)
end

function MapComponent:GetTotalBooksForDifficulty(Difficult: DifficultEnum.Difficults) : number
    local DifficultMultplier = {
        Easy = 1.5,
        Medium = 2.5,
        Hard = 3.5,
    }

    local getMultiReference = DifficultMultplier[Difficult] or DifficultMultplier.Easy
    return math.round(self.Attributes.MinBook * getMultiReference)
end

function MapComponent:SpawnBooks()
    local ValidSapwnAreas = GetValidSpawnsAreas(self.Instance)

    if not ValidSapwnAreas or #ValidSapwnAreas <= 0 then
        DebugServices:Panic(script.Name, "Error em create valid spawn areas.")
        return
    end

    local difficult = self.Attributes.Difficulty or CurrentMapConfig:GetDifficulty() or DifficultEnum.Easy
    local totalBooks = self:GetTotalBooksForDifficulty(difficult)
    local bookPlan = self:BuildBookPlan(totalBooks)
    self.BookPlan = bookPlan

    if #bookPlan <= 0 then
        DebugServices:Panic(script.Name, "Book plan is empty.")
        return
    end

    local bookParent = self.Instance:FindFirstChild("Books")
    if not bookParent then
        DebugServices:Panic(script.Name, "Books folder not found for book parent.")
        return
    end

    local stacksByKey = {}
    local stackList = {}

    for _, bookinfo in bookPlan do
        local spawnArea = ValidSapwnAreas[RandomGenerator:NextInteger(1, #ValidSapwnAreas)]
        local book = self:CreateBook(bookinfo)
        if not book then
            continue
        end

        local stack = SelectSpawnStack(spawnArea, stacksByKey, stackList)
        book:PivotTo(GetBookStackCFrame(book, stack))
        book.Parent = bookParent

        table.insert(self.ActiveBooks, book)
    end

    print(`[MapComponent] Created {#self.ActiveBooks} books.`)
end

MapComponent:OnStart(function(self)
    self.ActiveBooks = {}
    self:SpawnBooks()
end)

MapComponent:OnDestroy(function(self) end)

return MapComponent
