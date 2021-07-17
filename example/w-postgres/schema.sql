CREATE TABLE comment (
  id SERIAL PRIMARY KEY,
  text TEXT NOT NULL
);

CREATE TABLE dream_session (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  expires_at REAL NOT NULL,
  payload TEXT NOT NULL
);
