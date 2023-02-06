# IoT Connectivity Bootstrap

The purpose of this project is to provide a simple way of getting started quickly with connecting a MKR 1010 WIFI device with the Environment Shield to AWS Core IoT, read telemetry for the envioronemnt,  persist and store data. 


## Required Hardware 
* [Arduino MKR 1010 WIFI](https://store-usa.arduino.cc/products/arduino-mkr-wifi-1010)
* [Arduino MKR ENV Shield](https://store-usa.arduino.cc/products/arduino-mkr-env-shield-rev2)

* [USB 2.0 to Micro](https://www.walmart.com/ip/Mimifly-Micro-USB-Cable-2FT-2Pack-Android-Charger-USB-2-0-A-to-Micro-B-Charging-Cord-for-Samsung-Galaxy-S5-S6-S7-Edge-Note-4-5-LG-Moto-PS4-Black/711844429?athbdg=L1600) cable or [USB-C to Micro](https://www.walmart.com/ip/Cable-Matters-Cable-Matters-USB-C-to-Micro-USB-Cable-Micro-USB-to-USB-C-Cable-with-Braided-Jacket-6-6-Feet-in-Black/51374095) cable dependening on what ports your laptop has. You'll need to cable both to power the MKR 1010 WIFI and to upload the firmware. 

1. Attach the MKR 1010 ENV Shield on top of the the MKR 1010 Wifi. Make sure all of the pins align. It should only go on one way. 
2. Connect the USB cable to the MKR Wifi to power it. 
3. Download and install the drivers for the board. If you are using a Mac or Linux get the drivers from [here](https://www.silabs.com/products/development-tools/software/usb-to-uart-bridge-vcp-drivers). If you are on a Windows platform, download the drivers from [here](here).

		
## Setup your Arduino development environment and generate a Certificate Signing Request for your device

1. Follow the directions in [this](https://docs.arduino.cc/tutorials/mkr-wifi-1010/securely-connecting-an-arduino-mkr-wifi-1010-to-aws-iot-core) tutorial to setup the development environment, register your device with AWS Core IoT and test the connectivity of the device. 

***Notes:*** 

* Follow the directions up to and including the point in the ***Configuring and Adding the Board to AWS IoT Core*** where it asks you to download the generated Certificate Signning Request. For the actual registration of the device in AWS Core IoT, follow the directions outlined in ***Register the device using Terraform*** section below. 
* Copy the contentents of the Certificate Signing Request into a file named ***cert.csr** and place it in the ***/mkr_1010_env/secret/cert.csr*** directory. 
	

## Register the device using Terraform

Pre-requisites:
	* [Create an AWS Account and Install the AWS Client](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
	* [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
	* [Create a profile for Terraform to Use](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html****)
	* Apply the following permissions to your user by following the directions here for [Adding permissions by attaching policies directly to the user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_change-permissions.html):
		* AWSCertificateManagerFullAccess
		* AWSIoTThingsRegistration
		* AWSIoTFullAccess
 	

1. Follow the directions for [setting up Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build) on your machine. ***Note:** We will be using named profiles for this rather than environment variables so follow the directions for [configuring named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiFrles.html) to configure a profiel.  

2. Edit the main.tf located in the ***/Terraform*** directory. 
	* Change the region in the ***provider** section to the region you wish to use
	* Change the profile in the ***provider** section to the profile you created in step 1 above.
	* From the command line in the ***/Terraform directory*** execute the following command
		```
		terraform init
		terraform apply
		```
	This will generate a Core IoT device and a certificate that can be used to connect to the MQTT broker. 
	
3. Download the generated certificate by doing the following:
	1. Navigate to to ***AWS IoT / Manage / Things*** and select the thing named ***MKR_1010_ENV_THING*** This will bring you to the ***Thing Details*** form.
	2. Select the ***Certificates*** tab and click on the link for the ***Certificate ID***.
	3. This will bring you to the ***Details*** form. 
	4. Click on the butten labelled ***Actions*** in the upper right-hand corner and select ***Download***. Rename the file to ***certificate.pem.crt and move the file to the ***/mkr_1010_env/secret*** directory. You will later add the conntents of this to the ***arduino_secrets.h*** file. 

## Configure your Arduino Secrets
1.	Create a file named ***arduino_secrets.h** in the ***/mkr_1010_env/secret*** directory
2. Add the following two lines to that file for connecting to your WiFi and provide the 	appropriate values:

	```
	#define SECRET_SSID "your-ssid-here"
	#define SECRET_PASS "your-password-here"
	
	```

3. Add the following line to the ***arduino_secrets.h** file to designate your AWS IoT Broker:

	```
	#define SECRET_BROKER "your-broker-here"
	```
	
	Your AWS IoT broker can be found by navigating to	***AWS IoT/MQTT***. This will bring you to the broker details form. From here you can copy the value displayed under ***Endpoint*** and paste it in as the value for ***SECRET_BROKER***.
	
 
4. Add the following line to the ***arduino_secrets.h** file to desitnate the certificate:
	
	```
	const char SECRET_CERTIFICATE[] = R"(
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
)";
	```
	Replace the entire section from ***BEGIN CERTIFICATE*** to ***END CERTIFICATE*** with the contents from the file you downloaded and renamed to ***certificate.pem.crt***.
	
## Deploy your code to the MKR 1010
1. Open up the Arduino IDE you had previously installed. 
2. Open the file named ***mkr_1010_env.ino*** in teh ***mkr_1010_env*** directory.
3. The port and device should already have been configured in the steps above to set up the IDE. You should now be able to select ***Sketch/Upload** from the menu. This step will perform a compile and subseqent upload to the device. 
4. Open up the ***Serial Monitor** by selecting ***Tools/Serial Monitor*** from the menu. 
5. On the right hand side 	of the serial monitor pane, make sure it is configured for ***Both NL & CR** and ***9600 baud***. You should now begin to see status messages when the device attempts a connection and when it posts the telemetry. The telemetry message will look similar to the following in the serial monitor:

```
{
  "temperature": 77.1,
  "humidity": 36.047,
  "pressure": 1002.636,
  "illuminance": 18.065
}
```
6. You can no go into the AWS portal and verify that it is recieving the telemetry. From the portal, navigate to ***AWS IoT / MQTT test client***. Click on the ***Subscribe To Topic*** tab and set the ***Topic filter*** value to be ***environment/#***.
 
	
