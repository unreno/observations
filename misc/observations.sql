
--	Structure from SQL Server source table.


CREATE TABLE dbo.observations (
	id INT IDENTITY(1,1),
		CONSTRAINT observation_id PRIMARY KEY CLUSTERED (id ASC),

	chirp_id        INT NOT NULL,
	provider_id     INT NOT NULL,
	concept         VARCHAR(255) NOT NULL,
	started_at      DATETIME NOT NULL,
	ended_at        DATETIME,
	value           VARCHAR(255),
	units           VARCHAR(20),
	raw             VARCHAR(255),	--	is "raw" a keyword? sorta so may not be able to use it.
	downloaded_at   DATETIME,
	source_schema   VARCHAR(50) NOT NULL,
	source_table    VARCHAR(50) NOT NULL,
	source_id       INT NOT NULL,
	imported_at     DATETIME
		CONSTRAINT dbo_observations_imported_at_default 
		DEFAULT CURRENT_TIMESTAMP NOT NULL,
);

