#version 330 compatibility

#pragma vp_name       "REX Engine - Morphing"
#pragma vp_entryPoint "oe_rexEngine_morph"
#pragma vp_location   "vertex_model"
#pragma vp_order      "0.5"
#pragma vp_define     "OE_REX_VERTEX_MORPHING"

// stage
vec3 vp_Normal; // up vector

vec4 oe_layer_texc;
vec4 oe_layer_tilec;

out float oe_rex_morphFactor;

uniform sampler2D oe_tile_elevationTex;
uniform mat4      oe_tile_elevationTexMatrix;
uniform vec2	  oe_tile_morph;
uniform float     oe_tile_size;
uniform vec4	  oe_tile_key;

// SDK functions:
float oe_terrain_getElevation(in vec2 uv);


// Morphs a vertex using a neighbor.
void oe_rex_MorphVertex(inout vec3 position, inout vec2 uv, in vec3 neighborPosition)
{
   float halfSize        = (0.5*oe_tile_size)-0.5; //(oe_tile_size-1.0)*0.5;
   float twoOverHalfSize = 2.0/(oe_tile_size-1.0); 

   //vec2 fFractionalPart = fract(uv * vec2(halfSize)) * vec2(twoOverHalfSize);
   
   vec2 fractionalPart = fract(uv * halfSize) * twoOverHalfSize;
   uv = uv - (fractionalPart * oe_rex_morphFactor);
   uv = clamp(uv, 0, 1);

   vec3 morphVector = neighborPosition.xyz - position.xyz;
   position.xyz = position.xyz + morphVector*oe_rex_morphFactor;
}


// Compute a morphing factor based on model-space inputs:
float oe_rex_ComputeMorphFactor(in vec4 position, in vec3 up)
{
    // Find the "would be" position of the vertex (the position the vertex would
    // assume with no morphing)
	vec4 wouldBePosition = position;

	#ifdef OE_REX_VERTEX_MORPHING
        float elev = oe_terrain_getElevation( oe_layer_tilec.st );
	    //vec4 elevc = oe_tile_elevationTexMatrix * oe_layer_tilec;
	    //float elev = textureLod(oe_tile_elevationTex, elevc.st,0).r;
		wouldBePosition.xyz += up*elev;
	#endif

    vec4 wouldBePositionView = gl_ModelViewMatrix * wouldBePosition;
    
    float fDistanceToEye = length(wouldBePositionView.xyz); // or just -z.
	float fMorphLerpK  = 1.0f - clamp( oe_tile_morph[0] - fDistanceToEye * oe_tile_morph[1], 0.0, 1.0 );
    return fMorphLerpK;
}


void oe_rexEngine_morph(inout vec4 vertexModel)
{    
    // compute the morphing factor to send down the pipe.
    // we need this even if vertex-morphing is off since we use it for 
    // other things (like image blending)
    oe_rex_morphFactor = oe_rex_ComputeMorphFactor(vertexModel, vp_Normal);
    
#ifdef OE_REX_VERTEX_MORPHING
    vec3 neighborVertexModel = gl_MultiTexCoord1.xyz;
    oe_rex_MorphVertex(vertexModel.xyz, oe_layer_tilec.st, neighborVertexModel.xyz);
#endif
}
