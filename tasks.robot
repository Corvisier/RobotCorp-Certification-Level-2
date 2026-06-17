*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             RPA.HTTP
Library             RPA.FileSystem

*** Variables ***
${URL_CSV}    https://robotsparebinindustries.com/orders.csv
${URL}    https://robotsparebinindustries.com/#/robot-order

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Download orders file
    Read data file
    Closing Formalities

*** Keywords ***
Download orders file
    Download    ${URL_CSV}    overwrite=True
    Open Available Browser    ${URL}    maximized=True

Read data file
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Open robot order website    ${order}
    END

Open robot order website
    [Arguments]    ${order}
    Click Button    OK
    Sleep    1
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    //input[contains(@placeholder,'Enter the part number for the legs')]    ${order}[Legs]
    Input Text    xpath://*[@id="address"]    ${order}[Address]
    Sleep    1
    Click Button    xpath://*[@id="preview"]
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${order}[Order number].png
    Click Button    xpath://*[@id="order"]
    ${error}=    Does Page Contain Element    //div[contains(@class, "alert alert-danger")]
    WHILE    ${error}
        Sleep    1
        Click Button    xpath://*[@id="order"]
        ${error}=    Does Page Contain Element    //div[contains(@class, "alert alert-danger")]
    END

    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}${order}[Order number].pdf
    Log    ${pdf_path}
    Html To Pdf    ${order_results_html}    ${pdf_path}
    Log    ${pdf_path}

    ${robot_image}=    Create List    ${OUTPUT_DIR}${/}${order}[Order number].png
    Add Files To Pdf    ${robot_image}    ${pdf_path}    True
    Wait Until Page Contains Element    id:order-another
    Click Button    order-another

Closing Formalities
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}report.zip    include=*.pdf
    ${files}=    Find Files    ${OUTPUT_DIR}${/}*.pdf
    FOR    ${file}    IN    @{files}
        Remove File    ${file}
    END
    ${files}=    Find Files    ${OUTPUT_DIR}${/}*.png
    FOR    ${file}    IN    @{files}
        Remove File    ${file}
    END
    Close Browser