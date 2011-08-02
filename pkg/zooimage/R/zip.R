# Copyright (c) 2004-2010, Ph. Grosjean <phgrosjean@sciviews.org>
#
# This file is part of ZooImage
#
# ZooImage is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# ZooImage is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with ZooImage.  If not, see <http://www.gnu.org/licenses/>.

# Zip a .tif image and embed the corresponding .zim file as comment
# This requires the 'zip' program!
"zip.img" <- function (imagefile, zimfile = NULL, verify.zimfile = TRUE,
replace = FALSE, delete.source = TRUE, check.zip = TRUE, show.log = TRUE)
{
	# We need to switch to the root of sample dir for correct path in the zip file
	imagefile <- imagefile[1]
	inidir <- getwd()
	setwd(dirname(imagefile))
	on.exit(setwd(inidir))
	rootdir <- getwd()
	imagefile <- basename(imagefile)

	# Check if imagefile exists
	checkFileExists(imagefile, message = "%s doesn't exist, or is a directory!",
		force.file = TRUE)

	# Is there an associated .zim file?
	if (is.null(zimfile)) {
		sample.info <- get.sampleinfo(imagefile, "fraction",
			ext = extensionPattern("tif"))
		zimfile <- paste(sample.info, ".zim", sep = "")
	}

	### TODO: the zim file can be other parts of it , like Sample+A1.zim,
	###       instead of Sample+A.zim!
	if (!file.exists(zimfile))
		stop("creation of .zim file not implemented yet!")

	# Recheck .zim file
	checkFileExists(zimfile, message = "%s - doesn't exist or is corrupted!")

	# Verify the content of the .zim file
	if (verify.zimfile && verify.zim(zimfile) != 0)
		stop(sprintf("%s appears to be corrupted!", zimfile))

	# Zip the image in the '_raw' subdir and add the information from the .zim
	# file as comment
	zipfile <- paste(noext(imagefile), ".zip", sep = "")
	zipfile <- file.path(".", "_raw", zipfile)
	# Make sure that "_raw" subdir exists
	force.dir.create("_raw")

	#Copy or move the image to a .zip compressed file
	zip(zipfile, imagefile, comment.file = zimfile,
		delete.zipfile.first = replace)

	# Invisibly indicate success
	# Note: the .zim file is never deleted, because it can be used for other
	# purposes!
	return(invisible(TRUE))
}

# Compress all .tif images in the corresponding directory
# (at least those with an associated .zim file)
"zip.img.all" <- function (path = ".", images = NULL, check = TRUE,
replace = FALSE, delete.source = replace, show.log = TRUE, bell = FALSE)
{
	# This requires the 'zip' program!
	# Make sure it is available
	checkCapable("zip")

	# First, switch to that directory
	inidir <- getwd()
	checkDirExists(path)
	setwd(path)
	on.exit(setwd(inidir))
	path <- getwd()	# Indicate we are now in the right path

	# Get the list of images to process
	if (is.null(images))	# Compute them from path
		images <- dir(path, pattern = extensionPattern("tif")) # All .tif files

	# Make sure there is no path associated
	if (!all(images == basename(images)))
		stop("You cannot provide paths for 'images', just file names")

	# If there is no images in this dir, exit now
	if (is.null(images) || length(images) == 0)
		stop("There is no images to process in ", getwd())

	# Look at associated .zim files
	zimfiles <- paste(get.sampleinfo(images, "fraction",
		ext = extensionPattern("tif") ), ".zim", sep = "")
	keep <- file.exists(zimfiles)
	if (!any(keep))
		stop("You must create .zim files first (ZooImage Metadata)!")
	if (!all(keep)) {
    	warning(sum(!keep), " on ", length(keep),
			" images have no .zim file associated and will not be processed!")
		images <- images[keep]
		zimfiles <- zimfiles[keep]
	}

	# Check the zim files
	logClear()
	ok <- TRUE
	if (check) {
		cat("Verification of .zim files...\n")
		logProcess("Verification of .zim files...")
		ok <- TRUE
		zfiles <- unique(zimfiles)
		zmax <- length(zfiles)
		oks <- sapply( 1:zmax, function (z) {
			Progress(z, zmax)
			tryCatch({
				verify.zim(zfiles[z])
				return(TRUE)
			}, zooImageError = function (e) {
				logError(e)
				return(FALSE)
			})
		})
		ok <- all(oks)
		ClearProgress()
	}
	if (ok) {
		logProcess("\n-- OK, no error found. --")
		cat("-- Done! --\n")
	} else {
		stop("contains corrupted .zim files, compression not started!")
	}

	# If everything is ok compress these files
	imax <- length(images)
	cat("Compression of images...\n")
	logProcess("\nCompression of images...")

	oks <- sapply(1:imax, function (i) {
		Progress(i, imax)
		tryCatch({
			zip.img(images[i], verify.zimfile = FALSE, replace = replace,
				delete.source = delete.source, check.zip = FALSE,
				show.log = FALSE)
			logProcess("OK", images[i])
			return(TRUE)
		}, zooImageError = function (e) {
			logError(e)
			return(FALSE)
		})
	})

	ClearProgress()

	# Final report
	finish.loopfunction(ok, bell = bell, show.log = show.log)
}

# Use zipnote to extract the comment
"unzip.img" <- function (zipfile)
{
	# Extract .zim file, .tif file or both from a .zip archive
	zipnote(zipfile)
}

"unzip.img.all" <- function (path = ".", zipfiles = NULL)
{
	# Check that unzip is available
	checkUnzipAvailable()

	# Extract all .zim, .tif or both from .zip files
	stop("Not implemented yet!")
}