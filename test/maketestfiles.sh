#!/bin/sh
#
# Make test files using the CUPS imagetoraster filter and the test PPD
# in this directory...
#
# Usage:
#
#     ./maketestfiles.sh [depth(s)] [colorspace(s)] [order(s)] [all]
#                        [pstoraster | imagetoraster | cgpdftoraster |
#                         cgimagetoraster]
#

PPD=rasterview.ppd; export PPD
basedir=`dirname $0`
depths=""
cspaces=""
orders=""
filter=""
if test -d /usr/libexec/cups/filter; then
	filterpath="/usr/libexec/cups/filter"
else
	filterpath="/usr/lib/cups/filter"
fi

for file in imagetoraster cgimagetoraster; do
	if test -x $filterpath/$file; then
		filter=$file
		break
	fi
done

for option in $*; do
	case $option in
		1 | 2 | 4 | 8 | 16)
			depths="$depths $option"
			;;
		Chunked | Banded)
			orders="$orders $option"
			;;
		Planar)
			echo "Error: Planar order is not supported!"
			exit 1
			;;
		W | RGB | RGBA | K | CMY | YMC | CMYK | YMCK | KCMY | \
		KCMYcm | GMCK | GMCS | WHITE | GOLD | SILVER | RGBW | \
		CIEXYZ | CIELab | ICC1 | ICC2 | ICC3 | ICC4 | ICC5 | \
		ICC6 | ICC7 | ICC8 | ICC9 | ICCA | ICCB | ICCC | ICCD | \
		ICCE | ICCF)
			cspaces="$cspaces $option"
			;;
		pstoraster | imagetoraster | cgimagetoraster | cgpdftoraster)
			filter="$option"
			;;
		all)
			cspaces="W RGB RGBA K CMY YMC CMYK YMCK KCMY KCMYcm"
			cspaces="$cspaces GMCK GMCS WHITE GOLD SILVER RGBW"
			cspaces="$cspaces CIEXYZ CIELab ICC1 ICC2 ICC3 ICC4"
			cspaces="$cspaces ICC5 ICC6 ICC7 ICC8 ICC9 ICCA ICCB"
			cspaces="$cspaces ICCC ICCD ICCE ICCF"
			depths="1 2 4 8 16"
			orders="Chunked Banded"
			;;

		clean)
			rm -f *.ras *.log
			exit 0
			;;
			
		help)
			echo "Usage: $0 [colorspace(s)] [depth(s)] [order(s)] [filter]"
			echo "       $0 all"
			echo "       $0 clean"
			echo ""
			echo "Colorspaces: W RGB RGBA K CMY YMC CMYK YMCK KCMY KCMYcm"
			echo "             GMCK GMCS WHITE GOLD SILVER RGBW"
			echo "             CIEXYZ CIELab ICC1 ICC2 ICC3 ICC4"
			echo "             ICC5 ICC6 ICC7 ICC8 ICC9 ICCA ICCB"
			echo "             ICCC ICCD ICCE ICCF"
			echo ""
			echo "Depths: 1 2 4 8 16"
			echo ""
			echo "Orders: Chunked Banded"
			echo ""
			echo "Filters: cgpdftoraster cgimagetoraster imagetoraster pstoraster"
			echo ""
			exit 0
			;;
			
		*)
			echo "Unknown option '$option'!"
			exit 1
			;;
	esac
done

if test -z "$depths"; then
	depths="1 8"
fi

if test -z "$cspaces"; then
	cspaces="W RGB RGBW K CMY CMYK KCMY KCMYcm CIEXYZ CIELab"
fi

if test -z "$orders"; then
	orders="Chunked Banded"
fi

if test -z "$filter"; then
	echo No image filter found!
	exit 1
else
	echo Using $filter...
fi

for cspace in $cspaces; do
	for depth in $depths; do
		for order in $orders; do
			if test $depth -lt 8 -o $order = Banded; then
				case $cspace in
					CIEXYZ | CIELab | ICC1 | ICC2 | \
					ICC3 | ICC4 | ICC5 | ICC6 | ICC7 | \
					ICC8 | ICC9 | ICCA | ICCB | ICCC | \
					ICCD | ICCE | ICCF)
						continue
						;;
				esac
			fi

			echo -n $filter-$cspace-$depth-$order.ras:

			case $filter in
				pstoraster)
					($filterpath/pstops job user title 1 \
						"ColorModel=$cspace cupsBitsPerColor=$depth cupsColorOrder=$order" \
						$basedir/testprint.ps | \
					$filterpath/pstoraster job user \
						title 1 "") \
						> $filter-$cspace-$depth-$order.ras \
						2> $filter-$cspace-$depth-$order.log
					;;
				imagetoraster)
					$filterpath/imagetoraster job user \
						title 1 \
						"scaling=100 ColorModel=$cspace cupsBitsPerColor=$depth cupsColorOrder=$order" \
						$basedir/testprint.jpg \
						> $filter-$cspace-$depth-$order.ras \
						2> $filter-$cspace-$depth-$order.log
					;;
				cgpdftoraster)
					$filterpath/cgpdftoraster job user \
						title 1 \
						"ColorModel=$cspace cupsBitsPerColor=$depth cupsColorOrder=$order" \
						$basedir/testprint.pdf \
						> $filter-$cspace-$depth-$order.ras \
						2> $filter-$cspace-$depth-$order.log
					;;
				cgimagetoraster)
					$filterpath/cgimagetoraster job user \
						title 1 \
						"scaling=100 ColorModel=$cspace cupsBitsPerColor=$depth cupsColorOrder=$order" \
						$basedir/testprint.jpg \
						> $filter-$cspace-$depth-$order.ras  \
						2> $filter-$cspace-$depth-$order.log
					;;
			esac

			if test $? = 0; then
				echo " OK"
				rm -f $filter-$cspace-$depth-$order.log
			else
				echo " FAIL (see log file)"
				rm -f $filter-$cspace-$depth-$order.ras
			fi
		done
	done
done