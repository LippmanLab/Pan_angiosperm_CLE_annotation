import pandas as pd
import sys

def merge_overlapping_segments(df):
    # Group by the unique identifier column (column 1)
    grouped = df.groupby(1)
    merged_segments = []

    for identifier, group in grouped:
        # Create a new DataFrame for each group with relevant columns
        segments = group[[1, 8, 9]].copy()

        # Rename columns 8 and 9 to 'start' and 'end'
        segments.columns = [1, 'start', 'end']

        # Sort by the start position
        segments = segments.sort_values(by='start')

        # Initialize variables for merging segments
        start = segments.iloc[0]['start']
        end = segments.iloc[0]['end']

        # Merge overlapping segments within each group
        for i in range(1, len(segments)):
            if segments.iloc[i]['start'] <= end:
                end = max(end, segments.iloc[i]['end'])
            else:
                # Add the merged segment to the list
                merged_segments.append([identifier, start, end])
                start = segments.iloc[i]['start']
                end = segments.iloc[i]['end']

        # Add the last merged segment to the list
        merged_segments.append([identifier, start, end])

    # Create a new DataFrame with the merged segments
    merged_df = pd.DataFrame(merged_segments, columns=[1, 'start', 'end'])
    return merged_df

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Please provide the input file path as a command-line argument.")
        sys.exit(1)

    input_file = sys.argv[1]
    file = pd.read_table(input_file, header=None)
    file = file[file[10] < 0.08]

    new_file = merge_overlapping_segments(file)

    output_file = f'{input_file}_processed'
    new_file.to_csv(output_file, index=False)
