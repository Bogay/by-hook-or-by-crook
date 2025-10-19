shader_type canvas_item;

// ----------------------------------------------------
// 著色器參數 (可以在 Godot 檢查器中調整)
// ----------------------------------------------------

// 噪聲強度 (控制顫動的幅度)
uniform float noise_scale : hint_range(0.0, 10.0, 0.1) = 2.5;

// 噪聲貼齊間隔 (模擬低影格率, 例如 0.2 代表 5 FPS)
uniform float noise_snap_interval : hint_range(0.01, 0.5, 0.01) = 0.4;


// ----------------------------------------------------
// 輔助函式
// ----------------------------------------------------

// [1] 經典 2D 偽隨機函式 (用於生成單個浮點亂數)
float rand(vec2 st) {
    // 固定的“魔法”浮點數，用於製造混沌
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// [2] 3D 偽隨機函式 (從 3D 向量中生成 3D 噪聲)
vec3 random3(vec3 p) {
    // 使用 2D 亂數函式來分別計算輸出向量的 X, Y, Z 分量
    float rX = rand(p.xy);
    float rY = rand(p.yz);
    float rZ = rand(p.zx);
    return vec3(rX, rY, rZ);
}

// [3] 貼齊函式 (將一個值貼齊到另一個值的整數倍)
float snap(float x, float snap_val) {
    return snap_val * round(x / snap_val);
}


// ----------------------------------------------------
// 頂點著色器 (Vertex Shader)
// ----------------------------------------------------

void vertex() {
    // Godot 的頂點著色器中，`VERTEX` 變數代表物件空間中的頂點位置 (vec2)
    // 為了使用 3D 噪聲函式，我們將其提升為 vec3，Z 分量設為 0.0
    vec3 position_3d = vec3(VERTEX, 0.0);
    
    // [步驟 1] 離散化時間 (Snapping Time)
    // TIME 是 Godot 內建的全域時間變數 (秒)
    float snapped_time = snap(TIME, noise_snap_interval);
    
    // 將貼齊後的時間作為 Z 軸偏移，確保每次動畫更新時，種子都是新的
    // 這裡我們將時間向量加到位置上
    vec3 seed = position_3d + vec3(0.0, snapped_time, 0.0);

    // [步驟 2] 生成位移噪聲
    // 獲取一個 3D 的偽隨機向量 (範圍 [0.0, 1.0])
    vec3 random_vector = random3(seed);

    // 將範圍從 [0.0, 1.0] 重新映射到 [-1.0, 1.0]，讓位移可以朝所有方向
    vec2 noise_xy = (random_vector.xy * 2.0) - 1.0; 

    // [步驟 3] 應用位移
    // 根據 `noise_scale` 調整幅度和方向
    vec2 displacement = noise_xy * noise_scale;

    // 將位移加到原始頂點位置上
    VERTEX += displacement;
}