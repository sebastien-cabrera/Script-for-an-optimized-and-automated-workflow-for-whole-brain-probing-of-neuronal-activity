import os

import sys




import bgheatmaps as bgh

import pandas as pd

from bg_atlasapi.bg_atlas import BrainGlobeAtlas

from brainrender import settings

from matplotlib.colors import LinearSegmentedColormap

import matplotlib.pyplot as plt




import tkinter as tk

from tkinter import simpledialog as sd 

from tkinter import messagebox 







# Location of the folder to analyse (data_dirpath) and name of the file (data_filename)

project_root = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))

data_dirpath = os.path.join(project_root, "Representation_3D/Data")




data_filename = "M009_CC1_3DBrain1_stat.csv"




# Location of the file "MouseBrainRegionsTemplate-ref.xlsx"

mbrainreg_dirpath = os.path.join(project_root, "Representation_3D/Atlas/")

mousebrainreg_filename = "MouseBrainRegionsTemplate-ref.xlsx"




#Position on rostraux-caudal axis

PositionRC = 7000







"""

    Def script 

"""

# Def format of dialog box

class CustomDialog(sd.Dialog):

    def __init__(self, parent, title, buttons):

        self.buttons = buttons

        sd.Dialog.__init__(self, parent, title)




    def body(self, master):

        self.result = None

        for i, button in enumerate(self.buttons):

            button = tk.Button(master, text=button, width=100,
command=lambda i=i: self.onButtonClick(i))

            button.grid(row=i, column=2)




    def onButtonClick(self, index):

        self.result = self.buttons[index]

        master = self.master

        master.after_idle(self.ok)




    def get_result(self):

        return self.result




root = tk.Tk()

root.withdraw()







def setup_brainrender():

    """

        Brainrender settings

    """

    settings.WHOLE_SCREEN = False    # make the rendering window be smaller

    settings.SHOW_AXES = False

    settings.SHADER_STYLE = 'cartoon' #shiny, cartoon, metallic, plastic, glossy

    settings.ROOT_ALPHA = 0.05

    settings.BACKGROUND_COLOR = "white"

    settings.DEFAULT_CAMERA = "frontal_camera"




    #settings.vsettings.tiffOrientationType = 5







def find_directory(string, search_path, verbose=False):

# Search for a directory with the given string in the specified search_path.  Returns the path to the directory if found, or None if not found.

    for root, subdirs, files in os.walk(search_path):

        current_directory = os.path.basename(root)

        if string == current_directory:

            if verbose: print(root)

            return root

    return None




def find_file(filename, search_path, verbose=False):

# Search for a file with the given filename in the specified search_path.  Returns the path to the file if found, or None if not found.

    for root, dir, files in os.walk(search_path):

        if filename in files:

            file_path = os.path.join(root, filename)

            if verbose: print(file_path)

            return file_path

    return None




def read_file(file_path):

    # Get the file extension

    file_extension = file_path.split('.')[-1]




    # Read the file with Pandas based on the file extension

    if file_extension == 'csv':

        df = pd.read_csv(file_path)

    elif file_extension in ['xlsx', 'xls']:

        df = pd.read_excel(file_path)

    else:

        raise ValueError(f"File extension {file_extension}
not supported")

    return df




def merge_df(df1_atlasreg, df2_result):

    # Actual merge

    merge_df = pd.merge(df1_atlasreg, df2_result, on=['Name'],
how='inner', sort=True)

#   merge_df = pd.merge(df1_atlasreg, df2_result, on=['Name', 'Id'], how='inner', sort=True)




    # Typo correction : replace "." by "-" in the column titles

    merge_df = merge_df.rename(columns=lambda x: x.replace('.',
'_'))




    # Sorting by alphabetical order of Acronym

    sorted_df = merge_df.sort_values(by='Acronym')

    

    # Restrict the number of decimals in density

    if result_3 in sorted_df.columns:

        sorted_df[result_3] = sorted_df[result_3].round(decimals=3)

    print(sorted_df)

    return sorted_df

    

"""

    Main

"""

if __name__ == "__main__":

    """

        Variables

    """




    if not os.path.exists(data_dirpath):

        print("Path does not exists")

        sys.exit(1)

    data_fullpath = find_file(data_filename, data_dirpath)

    mousebrainreg_fullpath = find_file(mousebrainreg_filename, mbrainreg_dirpath)




    print(data_fullpath)

    if os.path.exists(data_fullpath) & os.path.exists(mousebrainreg_fullpath):

        # Read both files in 2 dataframes

        mb_df = read_file(mousebrainreg_fullpath)

        data_df = read_file(data_fullpath)

        

        # Display column titles for both dataframes

        print("Column names for: {mousebrainreg_fullpath}")

        mb_df.columns = mb_df.columns.str.title()

        print(mb_df.columns)

        print("Column names for: {data_fullpath}")

        data_df.columns = data_df.columns.str.title()

        print(data_df.columns)




        # Merge and combine 2 dataframe with respect to the column "Name" that contains the region name

        #work_df = merge_df(mb_df, data_df)

        

        # get regions two levels up the hierarchy

        atlas = BrainGlobeAtlas("allen_mouse_25um")

        

        #Regions of interest. Select L2, L3 or no line

        #regionsstudy = ['LSX', 'ACAd6a', 'mfbc', 'MOs2/3', 'GU5', 'STR', 'MOp6b', 'ACAv2/3', 'CLA', 'VL', 'MO', 'NDB', 'PAL']

        #work_df = work_df.loc[work_df['Acronym'].isin(regionsstudy)]

        #work_df = work_df[~work_df['Acronym'].isin(regionsstudy)]

        #print('Régions analysées :')

        #print(regionsstudy)




        """

        Dialog box

        """

        buttons_0 = ["Unique_Condition_to_represent", "Compare_2_Conditions", "Signaficative_region_(p-value)"]

        dialog_0 = CustomDialog(root, "What type of representation ?", buttons_0)

        result_0 = dialog_0.get_result()

        if result_0 == "Unique_Condition_to_represent": Q1 = "Condition for representation ?" 

        elif result_0 == "Signaficative_region_(p-value)": Q1 = "Condition for p-value representation ?" 

        elif result_0 == "Compare_2_Conditions" : Q1 = "Condition RED if upper ?"

        elif result_0 == None:

                messagebox.showwarning("ERROR","No type of representation selected !!!")

                exit()




        if result_0 == "Unique_Condition_to_represent" or result_0 == "Compare_2_Conditions":

            buttons_condition = set()

            valeurs_condition = data_df["Condition"].tolist()

            buttons_condition.update(valeurs_condition)

            print(buttons_condition)




            buttons_1 = list(buttons_condition)

            dialog_1 = CustomDialog(root, Q1, buttons_1)

            result_1 = dialog_1.get_result()

            print("1st dialog box : {}".format(result_1))




            if result_0 == "Compare_2_Conditions":

                buttons_2 = list(buttons_condition)

                dialog_2 = CustomDialog(root, "Condition BLUE if upper ?", buttons_2)

                result_2 = dialog_2.get_result()

                print("2nd dialog box : {}".format(result_2))




                if result_1 == result_2:

                    messagebox.showwarning("ERROR","Condition selected 2 times !!!")

                    exit()

                elif result_1 == None or result_2 == None:

                    messagebox.showwarning("ERROR","Condition don't selected !!!")

                    exit()

            

            all_columns = data_df.columns




            buttons_3 = [col for col in all_columns if
'dens' in col.lower() and not 'stat' in
col.lower()]

            print(buttons_3)




            dialog_3 = CustomDialog(root, "Cell population to analyze ?", buttons_3)

            result_3 = dialog_3.get_result()




            if result_3 == None:

                    messagebox.showwarning("ERROR","No cell population selected !!!")

                    exit()




        elif result_0 == "Signaficative_region_(p-value)":

            all_columns = data_df.columns

            buttons_3 = [col for col in all_columns if
'stat' in col.lower()]

            #buttons_3 = [col for col in all_columns if 'p' in col.lower()]




            print(buttons_3)




            dialog_3 = CustomDialog(root, "p-value to analyse ?", buttons_3)

            result_3 = dialog_3.get_result()




        root.destroy()




        # Merge and combine 2 dataframe with respect to the column "Name" that contains the region name

        work_df = merge_df(mb_df, data_df)

        result_3 = result_3.replace(".", "_")

        

        if result_0 == "Compare_2_Conditions":

            N1_density_dict = pd.Series(work_df[work_df['Condition']==result_1][result_3].values,
index=work_df[work_df['Condition']==result_1].Acronym).to_dict()

            N2_density_dict = pd.Series(work_df[work_df['Condition']==result_2][result_3].values,
index=work_df[work_df['Condition']==result_2].Acronym).to_dict()

            # Create the list of all regions studied in this experience

            regions = [*set(list(work_df.Acronym))]

            print(f"List of all brain regions studied in this experiment\n {regions}
\n")

            ratio_dict = {}

            for key in N1_density_dict :

                if (key in N2_density_dict) and (N1_density_dict[key]
> 0) and (N2_density_dict[key] > 0):

                    ratio_dict[key] = ((N1_density_dict[key] / (N2_density_dict[key]
+ N1_density_dict[key])))

                    ratio_dict[key] = round(ratio_dict[key], 3) #Round
"ratio_dict" and choose the number of decimals 

            print(ratio_dict)




            if result_3.lower() not in ["density", "densité"]:

                result_4 = result_3.replace("Dens_", "").replace("Dens", "")

            else : result_4 = "Densité"




            print("Condition RED if upper : "+result_1)

            print("Condition BLUE if upper : "+result_2)




            #Create personnalized blue_red scale

            seuilmin = 0.40 #Default : 0.40

            seuilmax = 0.60 #Default : 0.60

            # Def seuils et couleurs correspondantes

            thresholds = [seuilmin, 0.435, 0.470, 0.530, 0.565, seuilmax]
 

            colors = ['#000056', '#0254BE', '#FFFFFF', '#FFFFFF', '#FE0000', '#820000']

            normalized_thresholds = [(t - seuilmin) / (seuilmax - seuilmin) for
t in thresholds]

            # Création de la colormap personnalisée avec les seuils et couleurs

            blue_red_scale_NV = LinearSegmentedColormap.from_list('custom_cmap', list(zip(normalized_thresholds,
colors)), N=256) 




            setup_brainrender()

            f = bgh.heatmap(

                ratio_dict,

                position=(PositionRC, 5000, 5000,), 

                orientation="frontal",  # or 'sagittal', or 'horizontal' or a tuple (x,y,z)

                thickness=15000,

                title="Ratio "+result_1+"/("+result_2+"+"+result_1+")
de "+result_4,

                vmin=seuilmin,

                vmax=seuilmax, 

                zoom=1.4,

                format="3D",

                cmap="seismic",  # "seismic", or blue_red_scale_NV

            ).show()

            

            """

            # Création d'une figure avec une barre de couleur

            fig, ax = plt.subplots(figsize=(8, 1))

            cax = fig.add_axes([0.1, 0.5, 0.8, 0.4])  # Ajustez les paramètres pour positionner la barre de couleur

            

            # Affichage de la barre de couleur

            cb = plt.colorbar(plt.cm.ScalarMappable(cmap=blue_red_scale_NV), cax=cax, orientation='horizontal')

            cb.set_label('Valeur')

            plt.title('Échelle de couleur personnalisée')

            plt.show()

            """




        elif result_0 == "Unique_Condition_to_represent":

            N3_density_dict = pd.Series(work_df[work_df['Condition']==result_1][result_3].values,
index=work_df[work_df['Condition']==result_1].Acronym).to_dict()

            

            if result_3.lower() not in ["density", "densité"]:

                result_4 = "Densité de "+ result_3.replace("Dens_", "").replace("Dens",
"")

            else : result_4 = "Densité"

            #print("Analyse de la population"+result_4+"en condition"+result_1)




            setup_brainrender()

            f = bgh.heatmap(

                N3_density_dict,

                position=(PositionRC, 0, 12000,), # Position frontal, horizontal, sagittal

                orientation="frontal",  # or 'sagittal', or 'horizontal' or a tuple (x,y,z)

                thickness=15000,

                title=result_4+" en condition "+result_1,

                vmin=0,

                vmax=(max(N3_density_dict.values()))*0.7,

                zoom=1.4,

                format="3D",

                cmap="viridis",

            ).show()




        elif result_0 == "Signaficative_region_(p-value)":

            work_df = work_df.dropna(subset=[result_3])




            N4_density_dict = pd.Series(work_df[result_3].values, index=work_df.Acronym).to_dict()

            

            seuilmax = 1

            # Définition des seuils et des couleurs correspondantes

            thresholds = [0, 0.01, 0.010001, 0.05, 0.050001, seuilmax]
 

            colors = ['#FFD500', '#FFD500', '#FFFF62', '#FFFF62', '#FFFFFF']




            # Ajout des points de départ et d'arrivée

            thresholds = [0] + thresholds + [seuilmax]

            colors = [colors[0]] + colors + [colors[-1]]




            # Normalisation des seuils de 0 à 1

            normalized_thresholds = [t / seuilmax for t in thresholds]




            # Création de la colormap personnalisée avec les seuils et couleurs

            color_map = LinearSegmentedColormap.from_list('custom_cmap', list(zip(normalized_thresholds,
colors)), N=256)




            # Utilisation de la colormap personnalisée dans la fonction bgheatmaps

            setup_brainrender()

            f = bgh.heatmap(

                N4_density_dict,

                position=(PositionRC, 0, 12000,), 

                orientation="frontal",

                thickness=15000,

                title="P-value "+result_3,

                format="3D",

                vmin=0,

                vmax=seuilmax,

                zoom=1.4,

                cmap=color_map,

            ).show()

