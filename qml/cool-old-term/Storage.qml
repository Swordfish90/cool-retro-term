import QtQuick 2.1
import QtQuick.LocalStorage 2.0

Item {
    property bool initialized: false

    function getDatabase() {
         return LocalStorage.openDatabaseSync("coololdterm", "1.0", "StorageDatabase", 100000);
    }

    // At the start of the application, we can initialize the tables we need if they haven't been created yet
    function initialize() {
        var db = getDatabase();
        db.transaction(
            function(tx) {
                // Create the settings table if it doesn't already exist
                // If the table exists, this is skipped
                tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)');
          });

        initialized = true;
    }

    // This function is used to write a setting into the database
    function setSetting(setting, value) {
       if(!initialized) initialize();

       // setting: string representing the setting name (eg: “username”)
       // value: string representing the value of the setting (eg: “myUsername”)
       var db = getDatabase();
       var res = "";
       db.transaction(function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?);', [setting,value]);
                  //console.log(rs.rowsAffected)
                  if (rs.rowsAffected > 0) {
                    res = "OK";
                  } else {
                    res = "Error";
                  }
            }
      );
      // The function returns “OK” if it was successful, or “Error” if it wasn't
      return res;
    }
    // This function is used to retrieve a setting from the database
    function getSetting(setting) {
       if(!initialized) initialize();
       var db = getDatabase();
       var res="";
       db.transaction(function(tx) {
         var rs = tx.executeSql('SELECT value FROM settings WHERE setting=?;', [setting]);
         if (rs.rows.length > 0) {
              res = rs.rows.item(0).value;
         } else {
             res = undefined;
         }
      })
      // The function returns “Unknown” if the setting was not found in the database
      // For more advanced projects, this should probably be handled through error codes
      return res
    }

    function dropSettings(){
        var db = getDatabase();
        db.transaction(
            function(tx) {
                tx.executeSql('DROP TABLE settings');
          });
    }
}
