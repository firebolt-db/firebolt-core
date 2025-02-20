package com.firebolt.example;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;
import java.sql.SQLException;
import java.util.Scanner;
import java.util.logging.LogManager;

public class RunQuery {
    private static String readStdIn() {
        try (Scanner scanner = new Scanner(System.in)) {
            return scanner.useDelimiter("\\A").next();
        }
    }

    public static void main(String[] args) throws ClassNotFoundException, SQLException, IOException {
        // Read logging configuration to silence JDBC logs.
        LogManager.getLogManager().readConfiguration(RunQuery.class.getResourceAsStream("/logging.properties"));

        // Read the query from stdin.
        String query = readStdIn();

        // Load the Firebolt JDBC driver.
        Class.forName("com.firebolt.FireboltDriver");

        // Connect to Firebolt Core and create a statement. Note that the "firebolt"
        // database referenced in the connection string is created by default when
        // starting a Firebolt Core cluster.
        Connection connection = DriverManager.getConnection("jdbc:firebolt:firebolt?url=http://localhost:3473");
        Statement statement = connection.createStatement();

        // Execute the query specified on the command line.
        ResultSet resultSet = statement.executeQuery(query);

        // Print the column names.
        ResultSetMetaData resultSetMetaData = resultSet.getMetaData();
        for (int i = 1; i <= resultSetMetaData.getColumnCount(); i++) {
            System.out.print(resultSetMetaData.getColumnName(i) + "\t");
        }

        System.out.println();

        // Print the result rows.
        while (resultSet.next()) {
            for (int i = 1; i <= resultSetMetaData.getColumnCount(); i++) {
                System.out.print(resultSet.getString(i) + "\t");
            }

            System.out.println();
        }
    }
}
