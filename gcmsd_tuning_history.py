# Python script for extracting Agilent GC-MSD tuning results


import os
from pathlib import Path
from pypdf import PdfReader
import csv
from datetime import datetime, date


def get_data_lines(line_match, text):
    
    # This is a hacky fix, but it works for what we need at the moment...
    for i in range(len(text)):
        if line_match == text[f"{i}"][0]:
            if (line_match == 'Repeller') and (text[f"{i}"][2] == 'Amu'):
                continue
            elif (line_match == 'Ion') and (text[f"{i}"][1] == 'Polarity'):
                continue
            elif (line_match == 'Ion') and (text[f"{i}"][1] == 'Focus'):
                continue
            else:
                return text[f"{i}"]
                

def get_report_data(report):
    
    # Parse all PDF report text into a single string using pypdf, then split by newlines (\n)
    reader = PdfReader(f"{report}")
    page = reader.pages[0]
    page_text = page.extract_text()
    page_text_lines = page_text.splitlines()
    
    lines_dict = {}
    data_dict = {}
    line_matches = [
        'Filament',
        'Target',
        '69.00',
        '219.00',
        '502.00',
        'Air/Water',
        'Column(1)',
        'Repeller',
        'Report',
        'Ion'
        ]
    
    # Split line strings into lists by spaces, put each line list into an indexed dict key
    for line in range(len(page_text_lines)):
        line_text_list = page_text_lines[line].split()
        lines_dict.update({f"{line}": line_text_list})
        
    # Debug: Print text dict line by line    
    # for key, value in lines_dict.items():
        # print(f"{key}: {value}")
    
    for i in range(len(line_matches)):
        data_dict.update({f"{i}": get_data_lines(line_matches[i], lines_dict)})
    
    # Debug: Print data dict line by line
    # for key, value in data_dict.items():
        # print(f"{key}: {value}")
       
    return data_dict   


def get_tune_files():
    
    # Get list of all tune report .pdf files
    reports_all = [str(p) for p in Path('.').glob('*.pdf')]
    tune_reports = []
    
    # Filter for tuning reports (starting with 'atune' and 'etune')
    for i in range(len(reports_all)):
        report_name = reports_all[i]
        
        if str(report_name[0:5]) == 'atune':
            tune_reports = tune_reports + [report_name]
        elif str(report_name[0:5]) == 'etune':
            tune_reports = tune_reports + [report_name]
        # else:
            # continue
    
    return tune_reports


# def check_filename(filename):
    
    # file_exists = os.path.exists(filename)
    # if file_exists is True:
        # raise ValueError(f"{filename} already exists. Please rename or remove it from this folder before re-running this program.")
        

def create_filename():
    
    filename = f'{date.today()}_tune_report_history.csv'
    i = 0
    
    while os.path.exists(filename):
        filename = f'{date.today()}_tune_report_history_{i}.csv'
        i += 1
    
    return filename


def reformat_date(date_str):
    
    # Reformat report data from mm/dd/yy to yymmdd (matches dates in report file names)
    date_obj = datetime.strptime(date_str, "%m/%d/%Y")
    date_yymmdd = date_obj.strftime("%y%m%d")
    
    return date_yymmdd


def format_report_data(report):
    
    data = get_report_data(report)
    
    ymd_date = reformat_date(data["8"][2])
        
    # Define data for all columns
    report_data_formatted = [
        ymd_date,
        report,
        data["0"][1],
        *data["2"],
        *data["3"],
        *data["4"],
        data["5"][3],
        data["5"][5],
        data["5"][7],
        data["5"][9],
        data["5"][11],
        data["6"][2],
        data["6"][4],
        data["6"][8],
        data["9"][5],
        data["7"][9]
        ]
    
    return report_data_formatted


def main():
    
    # Debug: List of specific report file names
    reports = [
        'atune_240227.pdf'
        ]
    # reports = get_tune_files()
    
    # Manually define table headers since it's used multiple times
    mz_headers = [
        "Target_mz",
        "Actual_mz",
        "Abund",
        "Rel_Abund",
        "Iso_mz",
        "Iso_Abund",
        "Iso_Ratio"
        ]
    
    # Define all column names
    column_names = [
        "Date",
        "Filename",
        "Filament",
        *mz_headers * 3,
        "H2O",
        "N2",
        "O2",
        "CO2",
        "N2/H2O",
        "Column_1_Flow",
        "Column_2_Flow",
        "Interface_Temp",
        "EM Volts",
        "Gain Factor",
        ]
    
    # Check if .csv filename already exists
    # csv_filename = f'{date.today()}_tune_report_history.csv'
    # check_filename(csv_filename)
    
    # Write the columns into .csv file
    with open(
        csv_filename,
        mode='w',
        newline='',
        encoding='utf-8'
    ) as file:
        writer = csv.writer(file)
        writer.writerow(column_names)
        
        # Write the data from each reports as new rows in the .csv file
        for row in range(len(reports)):
            print(f"Loading: {reports[row]}")
            report_data = format_report_data(reports[row])
            writer.writerow(report_data)
            print(f"Success: {reports[row]}")
            
    print("Completed!")
    
    
if __name__ == "__main__":
    main()