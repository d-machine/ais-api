-- Client configuration table — stores this client's own state for GST intra/inter-state determination
-- Only one row should ever exist in this table.

CREATE TABLE wms.client_config (
    id SERIAL PRIMARY KEY,
    state_id INTEGER NOT NULL REFERENCES wms.state(id),
    lub INTEGER REFERENCES administration.user(id),
    lua TIMESTAMP NOT NULL DEFAULT NOW()
);
