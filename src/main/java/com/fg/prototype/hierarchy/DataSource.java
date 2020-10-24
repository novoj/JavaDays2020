package com.fg.prototype.hierarchy;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.sql.Connection;
import java.sql.SQLException;

/**
 * No extra information provided - see (selfexplanatory) method signatures.
 * I have the best intention to write more detailed documentation but if you see this, there was not enough time or will to do so.
 *
 * @author Jan Novotný (novotny@fg.cz), FG Forrest a.s. (c) 2020
 */
public class DataSource {
	private static final HikariConfig CONFIG = new HikariConfig();
	private static final HikariDataSource DATA_SOURCE;

	static {
		CONFIG.setJdbcUrl( "jdbc:oracle:thin:@127.5.0.3:1521:XE" );
		CONFIG.setUsername( "system" );
		CONFIG.setPassword( "oracle" );
		CONFIG.addDataSourceProperty( "cachePrepStmts" , "true" );
		CONFIG.addDataSourceProperty( "prepStmtCacheSize" , "250" );
		CONFIG.addDataSourceProperty( "prepStmtCacheSqlLimit" , "2048" );
		DATA_SOURCE = new HikariDataSource(CONFIG);
	}

	private DataSource() {}

	public static Connection getConnection() throws SQLException {
		return DATA_SOURCE.getConnection();
	}
}