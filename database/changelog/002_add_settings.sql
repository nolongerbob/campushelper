--liquibase formatted sql

--changeset campus_helper:002
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT
);
