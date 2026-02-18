--liquibase formatted sql

--changeset campus_helper:004
CREATE TABLE IF NOT EXISTS medicine_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0
);
