*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             OperatingSystem
Library             DateTime
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${image_directory}=         ${OUTPUT_DIR}${/}images/
${zip_directory}=           ${OUTPUT_DIR}${/}

*** Tasks ***
Order robots from the RobotSpareBin Industries Inc
    Open the robot order website
    Get csv url
    Get orders
    Name and create a ZIP
    Delete original images
    Close the browser

*** Keywords ***
Get csv url
    ${url}=    Get Secret    robot_address
    Download csv file    ${url}[value]

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    OK
    
Download csv file
    [Arguments]    ${url}
    Download    ${url}   overwrite=True

Get orders
    ${orders}=    Read table from CSV   orders.csv
    FOR    ${order}    IN    @{orders}
        Fill out 1 order    ${order}
        Save order details
        Return to order form
    END

Fill out 1 order
    [Arguments]    ${orders}
    Close the annoying modal
    Wait Until Page Contains Element    class:form-group
    Select From List By Index    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    class:form-control    ${orders}[Legs]
    Input Text    address    ${orders}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    2min    500ms    Place order

Place order
    Click Button    Order
    Page Should Contain Element    id:receipt

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    class:badge-success
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    id:receipt   outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Combine receipt with robot image to a pdf    ${receipt_filename}    ${image_filename}

Combine receipt with robot image to a pdf
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open Pdf    ${receipt_filename}
    @{pseduo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To Pdf    ${pseduo_file_list}    ${receipt_filename}    ${False}
    Close Pdf
    

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Delete original images
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}

Name and create a ZIP
    ${date}=    Get Current Date    exclude_millis=True
    ${name_of_zip}=    Get Value From User    Give the name for the zip of the orders:
    Log To Console    ${name_of_zip}_${date}
    Create the ZIP    ${name_of_zip}_${date}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${name_of_zip}

Close the browser
    Close Browser