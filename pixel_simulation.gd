extends Node2D


var mult: Vector3 = Vector3(1, 1, 1)

var rd: RenderingDevice
var shader: RID
var texture_a: RID
var texture_b: RID
var image_uniform_src: RDUniform
var image_uniform_dst: RDUniform
var tex_rd: Texture2DRD
var tex_rd2: Texture2DRD

func _ready() -> void:
	randomize()
	rd = RenderingServer.get_rendering_device()
	_load_shader()
	_create_textures()
	_create_uniforms()
	run_compute()
	
	tex_rd = Texture2DRD.new()
	tex_rd2 = Texture2DRD.new()
	tex_rd.texture_rd_rid = texture_a
	tex_rd2.texture_rd_rid = texture_b
	$Display.texture = tex_rd
	$Display2.texture = tex_rd2
	
	$Timer.start()
	$Timer.paused = true
	

func _load_shader() -> void:
	# Load shader
	var shader_file: RDShaderFile = load("res://compute_shader.glsl")	
	# Compile shader
	shader = rd.shader_create_from_spirv(shader_file.get_spirv())


func _get_start_image() -> Image:
	#var src_image := preload("res://test.png").get_image()
	#src_image.convert(Image.FORMAT_RGBAF)
	
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.3
	var src_image := noise.get_seamless_image(256, 256)
	src_image.convert(Image.FORMAT_RGBAF)
	for x in 256:
		for y in 256:
			var col: Color = src_image.get_pixel(x, y)
			if col.r > 0.5:
				src_image.set_pixel(x, y, Color.WHITE)
			else:
				src_image.set_pixel(x, y, Color.BLACK)
		
	return src_image

func _create_textures() -> void:
	# source setup
	var src_image := _get_start_image()
	
	var texture_format := RDTextureFormat.new()
	texture_format.width = 256
	texture_format.height = 256
	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	
	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)
	
	# destination setup
	var empty_image := Image.create(texture_format.width, texture_format.height, false, Image.FORMAT_RGBAF)
	
	# create textures
	var texture_view := RDTextureView.new()
	texture_a = rd.texture_create(texture_format, texture_view, [src_image.get_data()])
	texture_b = rd.texture_create(texture_format, texture_view, [empty_image.get_data()])


func _create_uniforms() -> void:	
	# Create src image uniform
	image_uniform_src = RDUniform.new()
	image_uniform_src.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform_src.binding = 0
	image_uniform_src.add_id(texture_a)
	
	# Create dst image uniform
	image_uniform_dst = RDUniform.new()
	image_uniform_dst.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform_dst.binding = 1
	image_uniform_dst.add_id(texture_b)
	

func run_compute() -> void:
	# Create storage buffer for the multiplier
	#var mult_bytes := PackedFloat32Array([mult.x, mult.y, mult.z]).to_byte_array()
	#var mult_buf: RID = rd.storage_buffer_create(mult_bytes.size(), mult_bytes)
	#
	# create the uniform
	#var mult_uniform := RDUniform.new()
	#mult_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#mult_uniform.binding = 2
	#mult_uniform.add_id(mult_buf)
	
	var pipeline := rd.compute_pipeline_create(shader)
	var uniform_set := rd.uniform_set_create([image_uniform_src, image_uniform_dst], shader, 0)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 32, 32, 1)
	rd.compute_list_end()
	
	# clean up
	#rd.free_rid(mult_buf)
	
func swap_textures() -> void:
	var tmp := texture_a
	texture_a = texture_b
	texture_b = tmp
		
	image_uniform_src.clear_ids()
	image_uniform_src.add_id(texture_a)
	image_uniform_dst.clear_ids()
	image_uniform_dst.add_id(texture_b)
	
	# Set the texture again
	tex_rd.texture_rd_rid = texture_a
	tex_rd2.texture_rd_rid = texture_b


func clean_up() -> void:
	rd.free_rid(shader)
	rd.free_rid(texture_a)
	rd.free_rid(texture_b)

func _exit_tree() -> void:
	clean_up()


func _on_timer_timeout() -> void:
	run_compute()
	swap_textures()


func _on_start_pressed() -> void:
	$Timer.paused = !$Timer.paused


func _on_step_pressed() -> void:
	run_compute()
	swap_textures()


func _on_swap_pressed() -> void:
	swap_textures()
