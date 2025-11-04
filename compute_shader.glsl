#[compute]
#version 450

layout(set = 0, binding = 0, rgba32f) uniform readonly image2D imageSrc;
layout(set = 0, binding = 1, rgba32f) uniform writeonly image2D imageDst;

layout(set = 0, binding = 2, std430) readonly buffer Params {
	float r;
	float g;
	float b;
}
params;

// Threads per work group
layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

// The code we want to execute in each invocation
void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

	vec4 color = imageLoad(imageSrc, uv);

	vec4 multiplier = vec4(params.r, params.g, params.b, 1.0f);

	vec4 output_color = color * multiplier;
	imageStore(imageDst, uv, output_color);
}
