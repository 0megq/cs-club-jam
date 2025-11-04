#[compute]
#version 450

const int gridWidth = 256;
const vec4 aliveColor = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 deadColor = vec4(0.0, 0.0, 0.0, 1.0);

layout(set = 0, binding = 0, rgba32f) uniform readonly image2D imageSrc;
layout(set = 0, binding = 1, rgba32f) uniform writeonly image2D imageDst;

// Threads per work group
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

bool isCellAlive(int x, int y) {
	vec4 pixel = imageLoad(imageSrc, ivec2(x, y));
	return pixel.g > 0.5;
}

int getLiveNeighbours(int x, int y) {
	int count = 0;
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			if( i == 0 && j == 0) continue;
			int nx = (x + i) % gridWidth;
			int ny = (y + j) % gridWidth;
			// if(nx >= 0 && nx < gridWidth && ny >= 0 && ny < gridWidth){
			vec4 pixel = imageLoad(imageSrc, ivec2(nx, ny));
			count += int(isCellAlive(nx, ny));
			// }
		}
	}
 return count;
}

void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

	int liveNeighbours = getLiveNeighbours(pos.x, pos.y);
	bool isAlive = isCellAlive(pos.x, pos.y);
	bool nextState = isAlive;
	if(isAlive && (liveNeighbours < 2 || liveNeighbours > 3)){
		nextState = false;
	} else if(!isAlive && liveNeighbours == 3){
		nextState = true;
	}
	
	vec4 newColor = nextState ? aliveColor : deadColor;
	
	imageStore(imageDst, pos, newColor);
}
