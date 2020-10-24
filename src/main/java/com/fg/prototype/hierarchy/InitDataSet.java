package com.fg.prototype.hierarchy;

import cz.fg.oss.pmptt.PMPTT;
import cz.fg.oss.pmptt.dao.memory.MemoryStorage;
import cz.fg.oss.pmptt.model.Hierarchy;
import cz.fg.oss.pmptt.model.HierarchyItem;
import lombok.extern.apachecommons.CommonsLog;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Random;
import java.util.Stack;
import java.util.concurrent.atomic.AtomicInteger;

import static java.util.Optional.ofNullable;

/**
 * No extra information provided - see (selfexplanatory) method signatures.
 * I have the best intention to write more detailed documentation but if you see this, there was not enough time or will to do so.
 *
 * @author Jan Novotný (novotny@fg.cz), FG Forrest a.s. (c) 2020
 */
public class InitDataSet {

	public static void main(String[] args) throws SQLException {
		try (final Connection connection = DataSource.getConnection()) {
			new RecursiveFiller(connection).fillData((short)5, (short)10, 10);
		}
	}

	@CommonsLog
	public static class RecursiveFiller {
		private final PreparedStatement categoryInsert;
		private final PreparedStatement productInsert;
		private final PreparedStatement productInCategoryInsert;
		private final Random rnd = new Random();
		private final PMPTT pmptt = new PMPTT(new MemoryStorage());

		public RecursiveFiller(Connection connection) throws SQLException {
			categoryInsert = connection.prepareStatement("insert into T_CATEGORY (CATEGORY_ID, NAME, PARENT, LVL, PATH, LEFT, RIGHT) values (?, ?, ?, ?, ?, ?, ?)");
			productInsert = connection.prepareStatement("insert into T_PRODUCT (PRODUCT_ID, NAME, PRICE, LEFT, RIGHT) values (?, ?, ?, ?, ?)");
			productInCategoryInsert = connection.prepareStatement("insert into T_PRODUCT_CATEGORY (PRODUCT_ID, CATEGORY_ID) values (?, ?)");
		}

		public void fillData(short levels, short categoryPerLevel, int productsPerLevel) throws SQLException {
			log.info("Generating started ...");
			final Hierarchy hierarchy = pmptt.getOrCreateHierarchy("test", (short)(levels + 1), (short)(categoryPerLevel + 1));
			recurse((short)1, levels, categoryPerLevel, productsPerLevel, hierarchy, null, new Path(), new AtomicInteger(0), new AtomicInteger(0));
			flush();
			log.info("Generating finished ...");
		}

		private void recurse(short level, short levels, short categoryPerLevel, int productsPerLevel, Hierarchy hierarchy, Integer parent, Path path, AtomicInteger categoryCounter, AtomicInteger productCounter) throws SQLException {
			for (int i = 0; i < categoryPerLevel; i++) {
				final int categoryId = categoryCounter.getAndIncrement();
				final String categoryName = "Category no. " + categoryId;
				final HierarchyItem hierarchyItem = ofNullable(parent)
						.map(String::valueOf)
						.map(it -> hierarchy.createItem(String.valueOf(categoryId), it))
						.orElseGet(() -> hierarchy.createRootItem(String.valueOf(categoryId)));

				categoryInsert.setInt(1, categoryId);
				categoryInsert.setString(2, categoryName);
				categoryInsert.setObject(3, parent);
				categoryInsert.setInt(4, level);
				categoryInsert.setString(5, path.getPath());
				categoryInsert.setLong(6, hierarchyItem.getLeftBound());
				categoryInsert.setLong(7, hierarchyItem.getRightBound());
				categoryInsert.addBatch();

				if (level == levels) {
					for (int j = 0; j < productsPerLevel; j++) {
						final int productId = productCounter.getAndIncrement();

						productInsert.setInt(1, productId);
						productInsert.setString(2, "Product no. " + productId);
						productInsert.setBigDecimal(3, new BigDecimal(String.valueOf(rnd.nextInt(10_000))));
						productInsert.setLong(4, hierarchyItem.getLeftBound());
						productInsert.setLong(5, hierarchyItem.getRightBound());
						productInsert.addBatch();

						productInCategoryInsert.setInt(1, productId);
						productInCategoryInsert.setInt(2, categoryId);
						productInCategoryInsert.addBatch();
					}
				}

				if (categoryCounter.get() % 10_000 == 0 || productCounter.get() % 10_000 == 0) {
					log.info("Categories: " + categoryCounter.get() +", products: " + productCounter.get());
					flush();
				}

				try {
					path.push(categoryId);
					if (level < levels) {
						recurse((short)(level + 1), levels, categoryPerLevel, productsPerLevel, hierarchy, categoryId, path, categoryCounter, productCounter);
					}
				} finally {
					path.pop();
				}
			}
		}

		private void flush() throws SQLException {
			int affected = 0;
			affected += Arrays.stream(categoryInsert.executeBatch()).sum();
			affected += Arrays.stream(productInsert.executeBatch()).sum();
			affected += Arrays.stream(productInCategoryInsert.executeBatch()).sum();
			log.info("Flushed " + affected + " inserts.");
		}

	}

	public static class Path {
		public static final String JOIN_CHAR = "/";
		private final Stack<String> path = new Stack<>();

		public void push(int categoryId) {
			this.path.push(String.valueOf(categoryId));
		}

		public void pop() {
			this.path.pop();
		}

		public String getPath() {
			final StringBuilder sb = new StringBuilder(JOIN_CHAR);
			for (String item : path) {
				sb.append(item).append(JOIN_CHAR);
			}
			return sb.toString();
		}

	}

}
