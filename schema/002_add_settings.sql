-- Миграция: таблица настроек (актуальная схема после изменения БД в ЛР8)

CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT
);
