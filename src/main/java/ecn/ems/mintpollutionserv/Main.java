/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package ecn.ems.mintpollutionserv;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.Driver;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;


/**
 *
 * @author Lucas Deswarte
 */
public class Main { 

    public static void main(String[] args) throws IOException {
        Connection connection=null;
        File configFile = new File("config.properties");

        Properties config;
        config = readConfigurationFile(configFile);

        try {
            Class.forName("org.postgresql.Driver");}
         catch (java.lang.ClassNotFoundException e) {
            System.err.println("class not found exception: " + e.getMessage());
        }
        var username = config.getProperty("username");
        var password = config.getProperty("password");
        var URL = config.getProperty("database_url", "jdbc:postgresql://localhost");
        var csvFilePath = config.getProperty("csvFilePath");
        try{
            connection = DriverManager.getConnection(URL, username, password);
            importFromFile(connection, csvFilePath);
            computePollution(connection);
            connection.close();
            Driver theDriver = DriverManager.getDriver(URL);
            DriverManager.deregisterDriver(theDriver);
        } catch (SQLException ex) {
            System.err.println("SQL exception: " + ex.getMessage());
        }
    }
    
    /**
     * reads a configuration file
     * @param configFile
     * @return 
     */
    static Properties readConfigurationFile(File configFile) {
    try (FileInputStream contents = new FileInputStream(configFile)) {
        var properties = new Properties();
        properties.load(contents);
        return properties;
    }   catch (FileNotFoundException ex) {
            Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
        } catch (IOException ex) {
            Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
        }
        return null;
}
    /**
     * Import in the database the points from the file 
     * The data format is considered to be always the same, if change in the data format this fonction needs to be modified
     * @param connect connection to the data base
     * @param filename the path to the file containing the points 
     */
    public static void importFromFile(Connection connect, String filename) {
        try {
            PreparedStatement stmtSuppress = connect.prepareStatement("DELETE FROM public.pollution");
            stmtSuppress.executeUpdate();
            String query = "INSERT INTO pollution(latitude,longitude,no2,nox,pm10,pm2p5,the_geom) VALUES(?,?,?,?,?,?,ST_Transform(ST_SetSRID(ST_Point(?,?),2154),4326))";
            PreparedStatement stmt = connect.prepareStatement(query);

            BufferedReader csvReader = new BufferedReader(new FileReader(filename));
            int i = 0;
            String row = csvReader.readLine();
            while (row != null && !row.startsWith("*END")) {
                    row = row.replace("e", "E"); //do this in order for the parseDouble methode to transform scientific notation into a double
                    if (!row.isBlank() && i>6 ) {
                        stmt.clearParameters();
                        String[] data = row.split("  ");
                        stmt.setDouble(1, Double.parseDouble(data[1]));
                        stmt.setDouble(2, Double.parseDouble(data[2]));
                        stmt.setDouble(3, Double.parseDouble(data[4]));
                        stmt.setDouble(4, Double.parseDouble(data[5]));
                        stmt.setDouble(5, Double.parseDouble(data[6]));
                        stmt.setDouble(6, Double.parseDouble(data[7]));
                        stmt.setDouble(7, Double.parseDouble(data[1]));
                        stmt.setDouble(8, Double.parseDouble(data[2]));
                        stmt.executeUpdate();
                }
                i++;
                row=csvReader.readLine();
            }
            csvReader.close();
            stmt.close();

        }catch(FileNotFoundException ex){
        Logger.getLogger(Main.class.getName()).log(Level.SEVERE,null,ex);
        } catch (IOException | SQLException ex) {
            Logger.getLogger(Main.class.getName()).log(Level.SEVERE, null, ex);
        }
        
    }
    /**
     * Launch the script computePollution.sql to compute the pollution 
     * @param dbConnection connection to the data base
     * @throws IOException
     * @throws SQLException 
     */
    public static void computePollution(
            Connection dbConnection
    ) throws IOException, SQLException{
        // Slurp `resources/â€¦/compute_pollution.sql`
        String sql;
        try (var inputStream = Main.class.getResourceAsStream("computePollutionBicycle.sql")) {
            sql = new String(inputStream.readAllBytes());
        }

        var importStatement = dbConnection.prepareStatement(sql);
        importStatement.execute();
    }
}
