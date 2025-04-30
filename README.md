# Pre-requisites:

Access to the Global Admin user for your local Microsoft Tenant

# Disclaimer:

The information provided hereby IT Glue is for general informational purposes only. All information is provided in good faith, however, we make no representations or warranties of any kind, express or implied, regarding the accuracy, adequacy, validity, reliability, availability, or completeness of any information provided.

Under no circumstances shall we have any liability to you for any loss or damage of any kind incurred as a result of the use of the information provided here. Your use of this information is solely at your own risk.

# Microsoft_Integration_App:

Automate the creation of App Registration and Service Principal with PowerShell

This script will create an App registration and a security group in your **Microsoft tenant** for you with all the **required API permissions** to connect integration with IT Glue.

This script will also prompt you to provide **Admin Consent** to the API permission added to the App to pull the information into IT Glue.

At the end, you will receive all the details that can be inserted into your IT Glue <-> Microsoft integration connection page:

![image](https://github.com/user-attachments/assets/216ae867-42ac-4fe6-a27d-71bf7d82f726)

# Steps still need to be performed:

1. The user will still need to create a Service Account - https://help.itglue.kaseya.com/help/Content/1-admin/microsoft/microsoft-gdap.html?Highlight=Microsoft%20integration%20GDAP
2. Add a GDAP Relationship in the Partner Center with the appropriate Entra Roles assigned to the Security Group - https://help.itglue.kaseya.com/help/Content/1-admin/microsoft/microsoft-gdap.html?Highlight=Microsoft%20integration%20GDAP
3. If you wish to **enable Password Rotation and Bitlocker**, you will need to add additional API permissions listed and follow the steps in the respective article below:
   a. [Password Rotation](https://help.itglue.kaseya.com/help/Content/1-admin/microsoft/microsoft-entra-id-password-rotation.htm?Highlight=Microsoft%20integration%20GDAP)
   b. [BitLocker](https://help.itglue.kaseya.com/help/Content/2-using/documentation-guide/BitLocker_Keys.html?Highlight=Bitlocker)
