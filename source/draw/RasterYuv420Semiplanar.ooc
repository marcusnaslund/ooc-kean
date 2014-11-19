//
// Copyright (c) 2011-2014 Simon Mika <simon@mika.se>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

use ooc-math
use ooc-base
import math
import structs/ArrayList
import RasterPacked
import RasterImage
import RasterYuvSemiplanar
import RasterMonochrome
import RasterUv
import Image
import Color
import RasterBgr
import StbImage
import io/File
import io/FileReader
import io/Reader
import io/FileWriter
import io/BinarySequence

RasterYuv420Semiplanar: class extends RasterYuvSemiplanar {
	init: func ~fromRasterImages (y: RasterMonochrome, uv: RasterUv) {
		this y = y
		this uv = uv
		this size = y size
		this stride = y stride
	}
	init: func ~fromSize (size: IntSize2D) { this init(size, CoordinateSystem Default, IntShell2D new()) }
	init: func ~fromStuff (size: IntSize2D, coordinateSystem: CoordinateSystem, crop: IntShell2D, byteAlignment := IntSize2D new()) {
		bufSize := RasterPacked calculateLength(size, 1) + RasterPacked calculateLength(size / 2, 2)
		this byteAlignment = byteAlignment
//    "RasterYuv420Semiplanar init ~fromStuff" println()
		super(ByteBuffer new(bufSize), size, coordinateSystem, crop)
	}
//	 FIXME but only if we really need it
//	init: func ~fromByteArray (data: UInt8*, size: IntSize2D) { this init(ByteBuffer new(data), size) }
	init: func ~fromByteBuffer (buffer: ByteBufferAbstract, size: IntSize2D, byteAlignment := IntSize2D new()) {
		this byteAlignment = byteAlignment
		super(buffer, size, CoordinateSystem Default, IntShell2D new())
	}
	init: func ~fromEverything (buffer: ByteBufferAbstract, size: IntSize2D, coordinateSystem: CoordinateSystem, crop: IntShell2D, byteAlignment := IntSize2D new()) {
		this byteAlignment = byteAlignment
		super(buffer, size, coordinateSystem, crop)
	}
	init: func ~fromRasterYuv420 (original: This) { super(original) }
	init: func ~fromRasterImage (original: RasterImage) {
		this init(original size, original coordinateSystem, original crop)
//		"RasterYuv420 init ~fromRasterImage, original: (#{original size}), this: (#{this size}), y stride #{this y stride}" println()
		y := 0
		x := 0
		width := this size width
		yRow := this y pointer as UInt8*
		yDestination := yRow
		uvRow := this uv pointer as UInt8*
		uDestination := uvRow
		vDestination := uvRow + 1
//		C#: original.Apply(color => *((Color.Bgra*)destination++) = new Color.Bgra(color, 255));
		f := func (color: ColorYuv) {
			(yDestination)@ = color y
			yDestination += 1
			if (x % 2 == 0 && y % 2 == 0) {
				uDestination@ = color u
				uDestination += 2
				vDestination@ = color v
				vDestination += 2
			}
			x += 1
			if (x >= width) {
				x = 0
				y += 1

				yRow += this y stride
				yDestination = yRow
				if (y % 2 == 0) {
					uvRow += this uv stride
					uDestination = uvRow
					vDestination = uvRow + 1
				}
			}
		}
		original apply(f)
	}
	/*shift: func (offset: IntSize2D) -> Image {
		result : This
		y = this y shift(offset) as RasterMonochrome
		uv = this uv shift(offset / 2) as RasterMonochrome
		result = This new(this size)
		result buffer copyFrom(y buffer, 0, 0, y length)
		result buffer copyFrom(uv buffer, 0, y length, uv length)
		result
	}*/
	create: func (size: IntSize2D) -> Image {
		result := This new(size)
		result crop = this crop
		result wrap = this wrap
		result
	}
	createY: func -> RasterMonochrome {
		yStride := Int align(this size width, byteAlignment width)
		ySize := Int align(this size height, this byteAlignment height) * yStride
		ySlice := ByteBufferSlice new(this buffer, 0, ySize)
		result := RasterMonochrome new(ySlice, this size, this byteAlignment width)
		ySlice decreaseReferenceCount()
		result
	}
	createUV: func -> RasterUv {
		yStride := Int align(this size width, byteAlignment width)
		ySize := Int align(this size height, this byteAlignment height) * yStride
		uvStride := Int align(this size width * 2, byteAlignment width)
		uvSize := Int align(this y size height, this byteAlignment height) * uvStride
		uvSlice := ByteBufferSlice new(this buffer, ySize, uvSize)
		result := RasterUv new(uvSlice, this size / 2, this byteAlignment width)
		uvSlice decreaseReferenceCount()
		result
	}
	copy: func -> This {
//  	"copying..." println()
		This new(this)
	}
	apply: func ~bgr (action: Func(ColorBgr)) {
		this apply(ColorConvert fromYuv(action))
	}
	apply: func ~yuv (action: Func (ColorYuv)) {
		yRow := this y pointer as UInt8*
		ySource := yRow
		uvRow := this uv pointer as UInt8*
		uSource := uvRow
		vSource := uvRow + 1
		width := this size width
		height := this size height

		for (y in 0..height) {
			for (x in 0..width) {
				action(ColorYuv new(ySource@, uSource@, vSource@))
				ySource += 1
				if (x % 2 == 1) {
					uSource += 2
					vSource += 2
				}
			}
			yRow += this y stride
			if (y % 2 == 1) {
				uvRow += this uv stride
			}
			ySource = yRow
			uSource = uvRow
			vSource = uvRow + 1
		}
	}
	apply: func ~monochrome (action: Func(ColorMonochrome)) {
		this apply(ColorConvert fromYuv(action))
	}

//	FIXME
//	openResource(assembly: ???, name: String) {
//		Image openResource
//	}
	operator [] (x, y: Int) -> ColorYuv {
		ColorYuv new(0, 0, 0)
		ColorYuv new(this y[x, y] y, this uv [x/2, y/2] u, this uv [x/2, y/2] v)
	}
	operator []= (x, y: Int, value: ColorYuv) {
		this y[x, y] = ColorMonochrome new(value y)
		this uv[x/2, y/2] = ColorUv new(value u, value v)
	}
	__destroy__: func {
		this y decreaseReferenceCount()
		this uv decreaseReferenceCount()
		this buffer decreaseReferenceCount()
	}
	open: static func (filename: String) -> This {
		x, y, n: Int
		requiredComponents := 3
		data := StbImage load(filename, x&, y&, n&, requiredComponents)
		buffer := ByteBuffer new(x * y * requiredComponents)
		// FIXME: Find a better way to do this using Dispose() or something
		memcpy(buffer pointer, data, x * y * requiredComponents)
		StbImage free(data)
		bgr := RasterBgr new(buffer, IntSize2D new(x, y))
		result := This new(bgr)
		bgr decreaseReferenceCount()
		return result
	}
	save: func (filename: String) {
		bgr := RasterBgr new(this)
		bgr save(filename)
		bgr decreaseReferenceCount()
	}
	saveBin: func (filename: String) {
		file := File new(filename)
		seq := BinarySequenceWriter new(FileWriter new(file))
		seq bytes(this buffer pointer, this buffer size)
		seq writer close()
	}
	openBin: static func (filename: String, width: Int, height: Int) -> This {
		fileReader := FileReader new(FStream open(filename, "rb"))
		bytes := width * height + (width * height / 2)
		data: UInt8* = gc_malloc_atomic(bytes)
		fileReader read((data as Char*), 0, bytes)
		fileReader close()
		fileReader free()
		buffer := ByteBuffer new(bytes, data as UInt8*)
		result := This new(buffer, IntSize2D new(width, height))
		buffer decreaseReferenceCount()
		result
	}
}
