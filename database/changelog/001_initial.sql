--liquibase formatted sql

--changeset campus_helper:001
CREATE TABLE IF NOT EXISTS users (
    login TEXT PRIMARY KEY,
    password TEXT NOT NULL,
    role TEXT NOT NULL
);

--changeset campus_helper:001-data
INSERT OR IGNORE INTO users(login, password, role) VALUES
    ('student', 'student', 'student'),
    ('teacher', 'teacher', 'teacher');
