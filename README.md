# Virtual Workshop Hands-On :

## Agenda:  

   1. Quick connect to Iot-Hub
   2. Visualize sensor data in web-app
   3. Build new firmware image in Cube-IDE
   4. Create a new table in azure sql database
   5. Create an azure stream analytics job to forward sensor data to your table
   6. Complete Azure Device Update


## Useful Content:

  - Command
    ```
    .\STM32U5_AZ_Setup.ps1 aedf9cbb-56df-47c5-82a7-9a57071cab8e -config true
    ```
  - Azure Username
    - stm32u585@outlook.com
  - Azure Password
    - XXXXXXXXXXXXXXXXXXXXX
  - Serial Monitor
    - https://serial.huhn.me/
  - Board Name
    - <Paste-name-here>
  - Web-App
    - https://vws-webapp.azurewebsites.net 
  - Resource Group
    - https://portal.azure.com/#@iotcloudservicesst.onmicrosoft.com/resource/subscriptions/52c2cfbe-e2e2-4bf4-a5ea-bc166f9fc637/resourceGroups/vws-rg/overview
  - SQL Database Username
    - vws
  - SQL Database Password
    - XXXXXXXXXX
  - Table Name
    - <Paste-name-here>
  - Create Table
    ```
    CREATE TABLE <boardname> (
      id INT PRIMARY KEY IDENTITY (1, 1),
      temperature int NOT NULL,
      humidity int NOT NULL,
      timestamp DATETIME
    );
    ```
  - Job Name
    - <Paste-name-here>
  - Create an ASA job
    ```
    SELECT
      CAST(temperature AS bigint) as temperature,
      CAST(humidity AS bigint) as humidity,
      System.Timestamp() as timestamp
    INTO
      <table-name>
    FROM
      vwsIotHub
    WHERE
      IoTHub.ConnectionDeviceId = '<board-name>'
    ```


