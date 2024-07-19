#!/bin/bash

# URL du fichier facefusion.zip
FILE_URL="https://www.dropbox.com/scl/fi/azn75v9t3qtsf3a9zjcvt/facefusion.zip?rlkey=6cuhrx8cpux9nqp3ylqoosc17&dl=1"

# Installer les paquets nécessaires
apt update
apt install -y git-all curl unzip
curl -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
apt install -y ffmpeg
apt-get install -y mesa-va-drivers

# Définir le chemin du workspace
WORKSPACE_DIR="/workspace/facefusion"

# Fichier de log
LOG_FILE="$WORKSPACE_DIR/setup.log"

echo "Starting setup.sh" >> $LOG_FILE
date >> $LOG_FILE

# Télécharger facefusion.zip
echo "Downloading facefusion.zip" >> $LOG_FILE
curl -L $FILE_URL -o /tmp/facefusion.zip
echo "Download completed" >> $LOG_FILE

# Extraction de facefusion.zip
echo "Extracting facefusion.zip" >> $LOG_FILE
mkdir -p $WORKSPACE_DIR
unzip /tmp/facefusion.zip -d $WORKSPACE_DIR
echo "Extraction completed" >> $LOG_FILE

# Installation de Miniconda dans le workspace
echo "Installing Miniconda" >> $LOG_FILE
bash Miniconda3-latest-Linux-x86_64.sh -b -p $WORKSPACE_DIR/miniconda
echo "Miniconda installed" >> $LOG_FILE

# Initialisation de conda
echo "Initializing conda" >> $LOG_FILE
eval "$($WORKSPACE_DIR/miniconda/bin/conda shell.bash hook)"
$WORKSPACE_DIR/miniconda/bin/conda init --all
echo "Conda initialized" >> $LOG_FILE

# Créez un second script pour les commandes post-initialisation
cat << EOF > $WORKSPACE_DIR/post_conda_init.sh
#!/bin/bash

# Définir le chemin du workspace
WORKSPACE_DIR="/workspace/facefusion"

LOG_FILE="\$WORKSPACE_DIR/post_conda_init.log"

echo "Starting post_conda_init.sh" >> \$LOG_FILE
date >> \$LOG_FILE

# Initialisation de conda
echo "Initializing conda in post_conda_init.sh" >> \$LOG_FILE
eval "\$($WORKSPACE_DIR/miniconda/bin/conda shell.bash hook)"

# Création de l'environnement facefusion
echo "Creating facefusion environment" >> \$LOG_FILE
conda create --prefix \$WORKSPACE_DIR/envs/facefusion python=3.10 -y
echo "Environment facefusion created" >> \$LOG_FILE

# Activation de l'environnement facefusion
echo "Activating facefusion environment" >> \$LOG_FILE
source activate \$WORKSPACE_DIR/envs/facefusion
echo "Environment facefusion activated" >> \$LOG_FILE

# Installation des paquets nécessaires
echo "Installing necessary packages" >> \$LOG_FILE
conda install -y -p \$WORKSPACE_DIR/envs/facefusion conda-forge::cuda-runtime=12.4.1 cudnn=8.9.2.26 conda-forge::gputil=1.4.0
conda install -y -p \$WORKSPACE_DIR/envs/facefusion conda-forge::openvino=2023.1.0
echo "Necessary packages installed" >> \$LOG_FILE

# Installation des dépendances spécifiques pour install.py
echo "Installing dependencies for install.py" >> \$LOG_FILE
pip install -r \$WORKSPACE_DIR/requirements.txt  # Assurez-vous que requirements.txt contient toutes les dépendances nécessaires pour install.py
echo "Dependencies for install.py installed" >> \$LOG_FILE

# Installation du paquet onnxruntime pour CUDA 11.8
echo "Installing onnxruntime" >> \$LOG_FILE
python \$WORKSPACE_DIR/install.py --onnxruntime cuda-11.8
echo "onnxruntime installed" >> \$LOG_FILE

# Mise à jour et installation des paquets Python supplémentaires
echo "Updating pip" >> \$LOG_FILE
pip install --upgrade pip
echo "Installing additional Python packages" >> \$LOG_FILE
pip install --upgrade bcrypt
pip install boto3
pip install passlib[bcrypt]
pip install mimetype
echo "Additional Python packages installed" >> \$LOG_FILE

# Vérification des installations
echo "Checking installed packages" >> \$LOG_FILE
pip freeze >> \$LOG_FILE

# Exécution de l'application
echo "Running app.py" >> \$LOG_FILE
python \$WORKSPACE_DIR/app.py
EOF

# Donner les permissions d'exécution au second script
chmod +x $WORKSPACE_DIR/post_conda_init.sh

# Exécuter le second script
echo "Running post_conda_init.sh" >> $LOG_FILE
$WORKSPACE_DIR/post_conda_init.sh
echo "post_conda_init.sh completed" >> $LOG_FILE

date >> $LOG_FILE
echo "setup.sh completed" >> $LOG_FILE
