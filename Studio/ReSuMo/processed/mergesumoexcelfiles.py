import pandas as pd
import os

def merge_excel_files(input_folder, output_file):
    # List all Excel files in the input folder
    files = sorted([f for f in os.listdir(input_folder) if f.endswith('.xlsx')])

    # List to store sheet names and computed K46 values for the recap
    recap_data = []
    recap_group_data = {}
    
    for file in files:
        file_path = os.path.join(input_folder, file)
        # Read the Excel file
        df = pd.read_excel(file_path)
        
        # Use the filename (without extension) as the sheet name
        sheet_name = os.path.splitext(file)[0]
        generate_time = int(sheet_name.split("_")[-1])
        sheet_name = sheet_name.replace(f"_{generate_time}", "")
        
        # Get the number of columns
        num_columns = len(df.columns)

        # Add summary row at the end of the sheet
        num_rows = len(df)
        

        # Add the sheet name and value from J{num_rows+2} to the recap data
        recap_data.append([sheet_name, generate_time / 10**9, f"='{sheet_name}'!$K${num_rows + 2}*60", f"='{sheet_name}'!$J${num_rows + 2}"])
        
        # Process group data
        key = sheet_name.replace("_no_pi", "").replace("_pi", "")
        index = 2 if "_no_pi" in sheet_name else 1

        if key not in recap_group_data:
            recap_group_data[key] = [key, "", ""]
        
        recap_group_data[key][index] = f"='{sheet_name}'!$J${num_rows + 2}"
        
        print(f"Added {file} as sheet {sheet_name}")
    
    # Convert recap_group_data to an array of arrays
    recap_group_data_array = [values for key, values in recap_group_data.items()]
    
    # Prepend headers
    recap_group_data_array.insert(0, ['Test', 'PI', 'NO_PI'])
    recap_group_data_array.insert(0, [])
    recap_group_data_array.insert(0, [])
    recap_group_data_array.insert(0, [])
    recap_group_data_array.insert(0, [])
    
    # Append recap_group_data_array to recap_data
    recap_data.extend(recap_group_data_array)
    
    # Create the recap sheet with the list of sheet names and their computed K46 values
    recap_df = pd.DataFrame(recap_data, columns=["Test", "Test Generation Time", "Mutation Testing Time", "Mutation Score"])
    
    # Write to Excel with recap as the first sheet
    with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
        recap_df.to_excel(writer, sheet_name='Recap', index=False)
        
        for file in files:
            file_path = os.path.join(input_folder, file)
            df = pd.read_excel(file_path)
            sheet_name = os.path.splitext(file)[0]
            generate_time = int(sheet_name.split("_")[-1])
            sheet_name = sheet_name.replace(f"_{generate_time}", "")
            # Get the number of columns
            num_columns = len(df.columns)

            # Add summary row at the end of the sheet
            num_rows = len(df)
            summary_row = ["All"]

            # Add SUM formulas for columns B to I (1 to 8 in 0-indexed format)
            for col in range(1, 9):  # Columns B (1) to I (8)
                summary_row.append(f"=SUM({chr(65 + col)}2:{chr(65 + col)}{num_rows + 1})")
            
            # Add the formula for the last column (J)
            summary_row.append(f"=(F{num_rows + 2}+I{num_rows + 2})/B{num_rows + 2}*100")

            # Add the sum of times 
            summary_row.append(f"=SUM({chr(65 + col + 2 )}2:{chr(65 + col + 2 )}{num_rows + 1})")

            # Ensure the summary row has the same number of columns as the dataframe
            if len(summary_row) < num_columns:
                summary_row.extend([''] * (num_columns - len(summary_row)))

            # Append the summary row to the dataframe
            df.loc[num_rows] = summary_row
            
            df.to_excel(writer, sheet_name=sheet_name, index=False)
    
    print(f"All files have been merged into {output_file}")

# Example usage:
input_folder = './'  # Replace with your folder path containing Excel files
output_file = 'Recaps.xlsx'  # Replace with your desired output filename
merge_excel_files(input_folder, output_file)
