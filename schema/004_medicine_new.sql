-- Изменение схемы БД на Test (ЛР8): новая таблица medicine_new

CREATE TABLE IF NOT EXISTS medicine_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0
);
