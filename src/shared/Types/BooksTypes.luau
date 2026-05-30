
export type BookThemes = "Romance" | "Action" | "Physic" | "Comedy"

export type Books = {
    Id: string,
    Title: string,
    Theme: BookThemes, -- Futuramente aqui será os temas
    Chapter: number,
    TotalChapters: number
}

return {}
