import shutil

with open("sources.list") as sources:
    for file in [
        source_raw.strip() for source_raw in sources if source_raw.strip()
    ]:  
        print(f"Copying file: {file}")
        shutil.copy(file, "./FPGA/CGoL/src")
