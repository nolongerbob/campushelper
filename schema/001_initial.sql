-- Актуальная схема БД campus_helper (SQLite)
-- Таблица пользователей для авторизации

CREATE TABLE IF NOT EXISTS users (
    login TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    role TEXT NOT NULL
);

-- Начальные данные (опционально, для разработки/тестов)
INSERT OR IGNORE INTO users (login, password, role) VALUES (
    ('student', 'student', 'student'),
    ('teacher', 'teacher', 'teacher')
);
