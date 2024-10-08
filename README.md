# AWS IoT Connectivity Bootstrap

The purpose of this project is to provide a simple way of getting started quickly with connecting a MKR 1010 WIFI device with the Environment Shield to Amazon's IoT Core service, read environmental telemetry from the device and persist the data into an S3 bucket.
The following AWS services will be used for this:
* [IoT Core](https://docs.aws.amazon.com/iot/latest/developerguide/what-is-aws-iot.html)
* [Kinesis Data Streams](https://docs.aws.amazon.com/streams/latest/dev/introduction.html)
* [Kinesis Firehose](https://docs.aws.amazon.com/firehose/latest/dev/what-is-this-service.html)
* [S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html)


## Required Hardware 
* [Arduino MKR 1010 WIFI](https://store-usa.arduino.cc/products/arduino-mkr-wifi-1010)
* [Arduino MKR ENV Shield](https://store-usa.arduino.cc/products/arduino-mkr-env-shield-rev2)
* [USB 2.0 to Micro](https://www.walmart.com/ip/Mimifly-Micro-USB-Cable-2FT-2Pack-Android-Charger-USB-2-0-A-to-Micro-B-Charging-Cord-for-Samsung-Galaxy-S5-S6-S7-Edge-Note-4-5-LG-Moto-PS4-Black/711844429?athbdg=L1600) cable or [USB-C to Micro](https://www.walmart.com/ip/Cable-Matters-Cable-Matters-USB-C-to-Micro-USB-Cable-Micro-USB-to-USB-C-Cable-with-Braided-Jacket-6-6-Feet-in-Black/51374095) cable dependening on what ports your laptop has. You'll need to cable both to power the MKR 1010 WIFI and to upload the firmware. 

1. Attach the MKR 1010 ENV Shield on top of the the MKR 1010 WiFi. Make sure all of the pins align. It should only go on one way. 
2. Connect the USB cable to the MKR WiFi to power it. 
3. Download and install the drivers for the board. Directions for installing the drivers on multiple platforms can be found [here](https://support.arduino.cc/hc/en-us/articles/4411305694610-Install-or-update-FTDI-drivers).

## Setup your Arduino development environment and generate a Certificate Signing Request for your device

1. Follow the directions in [this](https://docs.arduino.cc/tutorials/mkr-wifi-1010/securely-connecting-an-arduino-mkr-wifi-1010-to-aws-iot-core) tutorial to configure the Arduino development environment. Follow the directions up to and including the point in the ***Configuring and Adding the Board to AWS IoT Core*** where it asks you to download the generated Certificate Signing Request. Rather than doing it manually through the Portal, I've included it in a Terraform script which will register the device in AWS IoT Core and configure the services. These directions are outlined later in the ***Register the device using Terraform*** section. 

	**Note:**  In addition the the directions from that setup to install the required libraries, also install the following libraries:
	* Arduino_MKRENV (by Arduino)
	* Arduino-Json (by Arduino)

2. Once you have generated the signing request, copy the contents of the certificate signing request into a file named ***cert.csr*** and place it in the ***/mkr_1010_env/secret/*** directory. 

## Register the device using Terraform

1. Create an [AWS Account](https://aws.amazon.com/free). Your credit card will be required for this. The services we use should not cost much so long as you don't leave them up and running. At the end of this we'll perform a teardown to remove them.
2. Once you have an AWS Account you should set up an [administrative](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-set-up.html) user that you will use for executing the Terraform deploymennt.
3. [Create an AWS Account and Install the AWS Client](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html). Use the administrative user account for this configuration.
4. [Install the Terraform Client](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
5. [Create a profile to use for executing Terraform](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html***)
6. Apply the following permissions to your user by following the directions here for [Adding permissions by attaching policies directly to the user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_change-permissions.html):
	
	* AWSCertificateManagerFullAccess
	* AWSIoTThingsRegistration
	* AWSIoTFullAccess
	* AmazonKinesisFullAccess
	* IAMFullAccess
	* AmazonS3FullAccess
	* AmazonKinesisFullAccess

	**Note:** The above permissions allow full access. You should create custom policies for production environments.
7. Follow the directions for [setting up Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build) on your machine. ***Note:*** We will be using named profiles for this rather than environment variables so follow the directions for [configuring named profiles](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiFrles.html) to configure a profile.  
8. Edit the main.tf located in the ***/Terraform*** directory. 
	* Change the region in the ***provider** section to the region you wish to use
	* Change the profile in the ***provider** section to the profile you created in step 1 above.
	* From the command line in the ***/Terraform*** directory execute the following command
		```
		terraform init
		terraform apply
		```
	This will generate an IoT Core device and a certificate that can be used to connect to the MQTT broker. 
	
9. Download the generated certificate by doing the following:
	1. Navigate to ***AWS IoT / Manage / All Devices / Things*** and select the thing named ***MKR_1010_ENV_THING*** This will bring you to the ***Thing Details*** form.
	2. Select the ***Certificates*** tab and click on the link for the ***Certificate ID***.
	3. This will bring you to the ***Details*** form. Verify that the ***Status** is set to ***Active***. If it is not, select the ***Actions*** dropdown in the upper right hand corner and then select ***Activate***. 
	4. Click on the butten labeled ***Actions*** in the upper right-hand corner and select ***Download***. Rename the file to ***certificate.pem.crt and move the file to the ***/mkr_1010_env/secret*** directory. You will later add the contents of this to the ***arduino_secrets.h*** file. 
	5. Verify that there is a policy named ***mkr_1010_template_mkr_1010_policy*** in the list of policies at the bottom of the page. 
	6. Click on that policy link. this will bring you the ***Policies Detail Page***.
	7. Verify that the value in ***Policy Action*** is ***iot:\****. Keep in mind that this is a very open policy and should be more limited in a production environment. 
	8. You should see a version number ***1*** under ***All Versions***.
	 

## Configure your Arduino Secrets
This file contains secret values and is included when compiling the Arduino firmware. Since it contains values that should not be exposed, it is not included in this project and therefore must be created. 

1. Create a file named ***arduino_secrets.h** in the ***/mkr_1010_env/secret*** directory
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
	
 
4. Add the following line to the ***arduino_secrets.h** file to designate the certificate:
	
	```
	const char SECRET_CERTIFICATE[] = R"(
	-----BEGIN CERTIFICATE-----
	...
	-----END CERTIFICATE-----
	)";
	```

	Replace the entire section from ***BEGIN CERTIFICATE*** to ***END CERTIFICATE*** with the contents from the file you downloaded and renamed to ***certificate.pem.crt***.

	The following is an example of a complete file:

	```
	#define SECRET_SSID "your-ssid"
	#define SECRET_PASS "your-password"
	#define SECRET_BROKER "your-broker.us-east-1.amazonaws.com"
	
	const char SECRET_CERTIFICATE[] = R"(
	-----BEGIN CERTIFICATE-----
	xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	-----END CERTIFICATE-----
	)";
	
	```
	
## Deploy your code to the MKR 1010
1. Open up the Arduino IDE you had previously installed. 
2. Open the file named ***mkr_1010_env.ino*** in the ***mkr_1010_env*** directory.
3. The port and device should already have been configured in the steps above to set up the IDE. Double check it by selecting ***Tools / Port*** from the menu. 
4. From the menu select ***Sketch / Upload**. This step will perform a compile and subseqent upload to the device. 
4. Open up the ***Serial Monitor*** by selecting ***Tools / Serial Monitor*** from the menu. 
5. On the right hand side 	of the serial monitor pane, make sure it is configured for ***Both NL & CR*** and ***9600 baud***. You should now begin to see status messages when the device attempts a connection and when it posts the telemetry. The telemetry message will look similar to the following in the serial monitor:

	```
	{
	  "temperature": 77.1,
	  "humidity": 36.047,
	  "pressure": 1002.636,
	  "illuminance": 18.065
	}
	```
If you are not seeing messages similar to the one above check the following:
	* Be sure that the serial monitor is on and connected in the Arduino IDE
	* Hit the reset button (little white button) on the MKR 1010 ENV Shield. 
	* Validate that you have connected to the WiFi. You should see a message in the serial monitor that states ***You're connected to the network***. 
	* Validate that you have connected to the MQTT broker. You should see a message in the serial monitor that states ***You're connected to the MQTT broker***.


6. You can now go into the AWS portal and verify that it is receiving the telemetry. From the portal, navigate to ***AWS IoT / MQTT test client*** or in the ***Services*** search box enter in ***Message Broker***. Click on the ***Subscribe To Topic*** tab and set the ***Topic filter*** value to be ***environment/#*** then click on the ***Subscribe*** button. You should start to see the messages coming in.

## Kineses
The data that is being captured from the device will be persisted via a Kinesis stream consumed by a Kinesis Firehose which persists to an [S3 bucket](https://aws.amazon.com/s3/). 
The stream, firehose and bucket will have been created by the Terraform deployment you executed previously.
You should be able to verify that the data is entering the stream by 

1. In the search box for the AWS portal, type in ***Kinesis*** and click on the ***Kinesis*** service.
2. On the left hand menu select ***Data Streams***. 
3. Click on the link for ***mkr_1010_template_telemetry_stream***.
4. Click on the tab named ***Monitoring***. Data may not become available for a few minutes but, eventually you should start seeing data on the graphs. This designates that data is flowing through the stream. 
5. Click on the ***Delivery Streams*** item on the left-hand side. 
6. Click on the link for ***mkr_1010_template_telemetry_to_s3_delivery_stream***. 
7. Click on the ***Monitoring*** tab if it is not active. You should see data in the graphs designating that data is flowing through the firehose out to the S3 bucket.

## S3 Persistence
1. In the search box for the AWS portal, type in ***S3*** and click on the ***S3*** service.
2. From the listing that appears, click on the link for the item named ***mkr-1010-template-telemetry-bucket***.
3. Drill down through the directory structure and drill down the bottom level. The directory structure is partitioned out by Year/Month/Day/Hour. The partitions are used to organize the data in a structure that makes it efficient to read. This is also customizable.   
4. Click on one of the items at the bottom level.    
4. Click on the ***Download*** button. 
5. Once the file is downloaded, open it in a text editor. The download file should contain the data that was persisted.

## Debugging and Troubleshooting
Use the serial monitor as documented [here](https://docs.arduino.cc/software/ide-v2/tutorials/ide-v2-serial-monitor) to debug the firmware running on the MKR_1010 itself. The baud rage should be set to ***9600***. The output will let you know if you were able to  connect first to the WiFi then to the cloud. 

* If your IDE does not see the port that the MKR_1010 is connnected to, make sure you've installed the [FTDI drivers](https://ftdichip.com/drivers/vcp-drivers/).
* If you are getting an authorization error in the AWS Cloudwatch logs, check that the status of the certificate is Active in AWS. I've updated the README for this. 
* If you are getting an authorization error in the AWS Cloudwatch logs, Check that the value you have in your arduino_secrets.h is the contents of the certificate.pem.crt file and not the contents of the .csr file.



## Cleaning up
When you are done you can tear down the resources you created. This is to avoid any un-necessary costs. Of course, you can always continue to keep it up if you are ok with the costs.
You can go to the search box for the AWS portal, type in ***Billing*** and click on the ***Billing*** service to view your billing information.
Do clean up your resources do the following:

1. In your console, change to the terraform directory in the project.
2. Execute the following command:
   ```
   terraform destroy
	```
   This will tear down the infrastructure you have created. 

## Disclaimer and notes

* The software is provided "as is" without any warranty or guarantee of any kind.
* The user assumes all risks and responsibilities for the use of the software.
* The developer or provider of the software is not liable for any damages, including direct, indirect, incidental, or consequential damages, arising from the use or inability to use the software.
* The user acknowledges that the software may have defects or errors and agrees to use it at their own risk.
* The developer or provider of the software may update or modify the software at any time without notice.
* The user agrees to indemnify and hold the developer or provider of the software harmless from any claims, damages, or losses arising from the use of the software.
* This software is not production ready
* If you would like to make changes to the README directions, feel free to submit the changes. 
