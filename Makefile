SINGULARITY_IMAGE=library://boyewo/collection/io500-singularity.sif
LOCAL_IMAGE=io500-singularity.sif
CONFIG_DIR=$(HOME)/io500_config
DATA_DIR=/mnt  # Replace /mnt with the file system to be accessed
RESULT_DIR=$(DATA_DIR)/datavolume  # Replace /mnt/datavolume with the correct result directory
CONFIG_FILE=$(CONFIG_DIR)/config.ini

# Default target
all: run

# Pull the Singularity image from the registry
pull:
	singularity pull $(LOCAL_IMAGE) $(SINGULARITY_IMAGE)

# Run the Singularity command
run: pull
	sudo singularity exec --bind "$(CONFIG_DIR):/opt/io500/config" --bind "/mnt:/mnt" $(LOCAL_IMAGE) bash -c "\
	cp /opt/io500/config-minimal.ini \"$(CONFIG_FILE)\" && \
	echo '[global]' >> \"$(CONFIG_FILE)\" && \
	echo 'datadir = \"$(RESULT_DIR)\"' >> \"$(CONFIG_FILE)\" && \
	echo '' >> \"$(CONFIG_FILE)\" && \
	echo '[debug]' >> \"$(CONFIG_FILE)\" && \
	echo 'stonewall-time = 300' >> \"$(CONFIG_FILE)\" && \
	cd /mnt/datavolume && \
	/opt/io500/io500 \"$(CONFIG_FILE)\" \
	"

