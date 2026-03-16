CREATE TABLE IF NOT EXISTS wms.status_code (
    entity  VARCHAR(50)  NOT NULL,
    code    INTEGER      NOT NULL,
    label   VARCHAR(100) NOT NULL,
    PRIMARY KEY (entity, code)
);
