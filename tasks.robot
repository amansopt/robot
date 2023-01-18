*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Variables ***
${OUTPUT_OTHERS}=       ${OUTPUT_DIR}${/}Others
${OUTPUT_RECEIPT}=      ${OUTPUT_DIR}${/}Receipt


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Set Up Directories
    #Input CSV file
    Download the csv file
    Read CSV and fill form
    Create ZIP package from PDF files
    [Teardown]    Cleanup temporary directory


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/

Get and log the value of the vault secrets using the Get Secret keyword
    ${secret}=    Get Secret    credentials
    Input Text    id:password    ${secret}[username]
    Input Password    id:password    ${secret}[password]

Set Up Directories
    Create Directory    ${OUTPUT_OTHERS}
    Create Directory    ${OUTPUT_RECEIPT}

Input CSV file
    Add text input    file    label=link to csv file
    ${result}=    Run dialog
    Download    ${result.file}    overwrite=True

Download the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Read CSV and fill form
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Get Orders    ${order}

        Click Button    order
        ${result}=    Run Keyword And Return Status
        ...    Wait Until Element Is Visible
        ...    //*[@class="alert alert-danger"]
        IF    '${result}' == '${TRUE}'
            Log    'erro servidor'
            # Click Button    //*[@id="order"]
        ELSE
            Wait Until Element Is Visible    receipt
            Preview Robot    ${order}[Order number]
            Export PDF    ${order}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
            Click Button    order-another
        END
    END

Get Orders
    [Arguments]    ${order}
    Go To    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${ordernumber}
    Open Pdf    ${OUTPUT_OTHERS}${/}${ordernumber}.pdf
    ${list_pdf}=    Create List
    ...    ${OUTPUT_OTHERS}${/}${ordernumber}.pdf
    ...    ${OUTPUT_OTHERS}${/}${ordernumber}.png
    Add Files To Pdf    ${list_pdf}    ${OUTPUT_RECEIPT}${/}${ordernumber}.pdf
    Close Pdf    ${OUTPUT_OTHERS}${/}${ordernumber}.pdf

Export PDF
    [Arguments]    ${ordernumber}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_OTHERS}${/}${ordernumber}.pdf

Preview Robot
    [Arguments]    ${ordernumber}
    Screenshot    robot-preview-image    ${OUTPUT_OTHERS}${/}${ordernumber}.png

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_RECEIPT}
    ...    ${zip_file_name}

Cleanup temporary directory
    Remove Directory    ${OUTPUT_RECEIPT}    True
    Remove Directory    ${OUTPUT_OTHERS}    True

# Submit Order
#    Click Button    order
#    #Alerta
#    ${result}=    Run Keyword And Return Status    Wait Until Element Is Visible    //*[@class="alert alert-danger"]
#    IF    '${result}' == '${TRUE}'
#    Log    'erro servidor'
#    # Click Button    //*[@id="order"]
#    ELSE
#    Wait Until Element Is Visible    receipt
#    Export PDF
#    Click Button    order-another
#    END

# 0rder another
#    Click Button    order-another

# Alerta
#    TRY
#    Wait Until Page Contains Element    id:order-another
#    Click Button    order-another
#    EXCEPT
#    Click Button    order
#    Alerta
#    END
