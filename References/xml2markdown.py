#   =========================================================================================================================================
#   =================================== Extract Data from XML files and create Markdown Reference Sheets.   =================================
#   =========================================================================================================================================

#   I hate XML!

#   =========
#   LIBRARIES
#   =========

import pandas                   # For fancy dataframes.
import pandas_read_xml as pdx   # To convert XML to fancy dataframes.

#   =============
#   READ XML FILE
#   =============

enumerationsDataFrame = pdx.read_xml(
    "Ref_Enumerations.xml", ["root", "enumerations", "enumeration"])

statObjectDefsDataFrame = pdx.read_xml(
    "Ref_StatObjectDefinitions.xml", ["root", "stat_object_definitions", "stat_object_definition"])

#   ======================
#   CREATE MARKDOWN TABLES
#   ======================

#   Enumerations.md
#   ===============

#       Markdown header
#       ---------------

enumerationsMarkdownContent = "# Reference: Enumerations\n\n---\n\n## Table of Contents\n\n"

#       Table of Contents
#       -----------------

# e.g.:     - [Surface Type](#surface-type)
for index, content in enumerationsDataFrame.iterrows():
    enumerationsMarkdownContent += "- [" + content["@name"] + \
        "]" + "(#" + content["@name"].replace(" ", "-") + ")\n"

enumerationsMarkdownContent += "\n---\n\n"

#       Markdown Content
#       ----------------

#   Extract data as dataframe
for index, content in enumerationsDataFrame.iterrows():
    try:
        itemDataFrame = pandas.DataFrame.from_dict(content["items"]["item"])
    except ValueError:  # For Act and SkillElements that have only one entry.
        itemDataFrame = pandas.DataFrame([{"@index": 0, "@value": 1}])

#   Create markdown tables from dataframe
    enumerationsMarkdownContent += "## " + content["@name"] + "\n\n" + \
        pandas.DataFrame.to_markdown(itemDataFrame) + "\n\n"

#   StatObjectDefinitions.md
#   ========================

#       Markdown header
#       ---------------

statObjectDefsMarkdownContent = "# Reference: Stat Object Definitions\n\n---\n\n## Table of Contents\n\n"

#       Table of Contents
#       -----------------

#   Reduced data-frame
statObjectDefsDataFrame = statObjectDefsDataFrame[[
    "@name", "@category", "field_definitions"]]

#   e.g.:   - [ItemCombo: ItemComboProperties](#itemcombo-itemcomboproperties)
for index, content in statObjectDefsDataFrame.iterrows():
    text = content["@category"] + ": " + content["@name"]
    statObjectDefsMarkdownContent += "- [" + \
        text + "](#" + text.replace(" ", "-") + ")\n"

statObjectDefsMarkdownContent += "\n---\n\n"

#       Markdown Content
#       ----------------

for index, content in statObjectDefsDataFrame.iterrows():
    #   Markdown table-title
    statObjectDefsMarkdownContent += "## " + \
        content["@category"] + ": " + content["@name"] + "\n\n"
    #   Extract data as data-frame
    fieldDefsDataFrame = pandas.DataFrame.from_dict(
        content["field_definitions"]["field_definition"])
    #   Clean dataframe
    fieldDefsDataFrame = fieldDefsDataFrame.drop(
        columns=["@display_name", "@export_name"])
    fieldDefsDataFrame = fieldDefsDataFrame.dropna(how="all")
    fieldDefsDataFrame = fieldDefsDataFrame.fillna("")

    #   Modify dataframe
    cols = list(fieldDefsDataFrame.columns.values)
    #   Remove wierd stat-descriptions column
    if "stat_descriptions" in cols:
        fieldDefsDataFrame = fieldDefsDataFrame.drop(
            columns="stat_descriptions")
    #   Add links to Enumerations.md
    if "@enumeration_type_name" in cols:
        fieldDefsDataFrame["@enumeration_type_name"] = "[" + fieldDefsDataFrame["@enumeration_type_name"] + \
            "](Enumerations.md#" + \
            fieldDefsDataFrame["@enumeration_type_name"].str.replace(
                " ", "-") + ")"
    #   Remove bad-links
    fieldDefsDataFrame = fieldDefsDataFrame.replace("[](Enumerations.md#)", "")
    #   Move @description column to the end
    if "@description" in cols:
        cols.pop(cols.index("@description"))
        fieldDefsDataFrame = fieldDefsDataFrame[cols + ["@description"]]

    #   Create markdown table
    statObjectDefsMarkdownContent += pandas.DataFrame.to_markdown(
        fieldDefsDataFrame) + "\n\n"

#   ===================
#   WRITE MARKDOWN FILE
#   ===================

#   Extra pedantic removal of the last "\n"
enumerationsMarkdownContent = enumerationsMarkdownContent.rstrip() + "\n"
statObjectDefsMarkdownContent = statObjectDefsMarkdownContent.rstrip() + "\n"

#   Write Enumerations.md
with open("Enumerations.md", "w") as markdownFileEnumerations:
    markdownFileEnumerations.write(enumerationsMarkdownContent)
markdownFileEnumerations.close()

#   Write StatObjectDefinitions.md
with open("StatObjectDefinitions.md", "w") as markdownFilestatObjectDefs:
    markdownFilestatObjectDefs.write(statObjectDefsMarkdownContent)
markdownFilestatObjectDefs.close()

#   ########################################################################################################################################
