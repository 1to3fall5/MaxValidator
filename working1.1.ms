-- 定义一个空的全局数组，用于存储场景对象的数据
global sceneObjectsData = #()
global objectFormData = #()

-- 将布尔值转换为字符串
fn boolToString yesNo = if yesNo then "Yes" else "No"
	
-- 计算UV通道数量和formColor
fn countUVChannels obj = (
    local numChannels = 0
    local formColor = if polyOp.getMapSupport obj  2 then "Red" else "White" -- 确定颜色属性
	for i = 1 to 99 do (
		-- 检查对象的每个多边形是否支持UV映射
		if polyOp.getMapSupport obj i do (
			numChannels += 1
		)
	)
    return #(numChannels as string, formColor) -- 返回包含numChannels和formColor的数组
)

-- 检测是否存在重叠顶点
fn detectOverlappingVertices obj threshold:0.001 = (
    local hasOverlapping = false
    for i=1 to polyOp.getNumVerts obj do (
        for j=i+1 to polyOp.getNumVerts obj do (
            if (length (polyOp.getVert obj i - polyOp.getVert obj j) < threshold) and
               (polyOp.getFacesUsingVert obj i * polyOp.getFacesUsingVert obj j).numberset == 0 do
            (
                hasOverlapping = true
                exit with hasOverlapping
            )
        )
    )
	local formColor = if hasOverlapping then "Red" else "White" -- 确定颜色属性
    return #(boolToString hasOverlapping, formColor) -- 返回包含hasOverlapping和formColor的数组
)

-- 计算对象的材质数量
fn countObjectMaterials obj = (
    local mat = obj.material
    local numMaterials = 0
    if mat != undefined then (
        if classOf mat == MultiMaterial then
            numMaterials = mat.numsubs
        else
            numMaterials = 1
    ) 
	local formColor = if numMaterials > 2 then "Red" else "White" -- 确定颜色属性
    return #(numMaterials as string, formColor) -- 返回包含numMaterials和formColor的数组
)

-- 检查对象的UV坐标是否都在第一象限
fn checkAllUVsInFirstQuadrant obj = (
    local allChannelsInFirstQuadrant = true
    tret = countUVChannels obj
    local numChannels = tret[1] as integer

    for channel = 1 to numChannels do (
        if polyOp.getMapSupport obj channel do (
            local numMapVerts = polyOp.getNumMapVerts obj channel
            for i = 1 to numMapVerts do (
                local uvVert = polyOp.getMapVert obj channel i
                if uvVert.x < 0 or uvVert.x > 1 or uvVert.y < 0 or uvVert.y > 1 then (
                    allChannelsInFirstQuadrant = false
                    exit with allChannelsInFirstQuadrant
                )
            )
        )
    )
    local formColor = if allChannelsInFirstQuadrant then "Red" else "White" -- 确定颜色属性
    return #(boolToString allChannelsInFirstQuadrant, formColor) -- 返回包含allChannelsInFirstQuadrant和formColor的数组
)

-- 获取对象的面数量
fn getObjectFaceCount obj = (
    local faceCount = 0
    local formColor = if polyOp.getMapSupport obj  2 then "Red" else "White" -- 确定颜色属性
	faceCount = polyOp.getNumFaces obj
    return #(faceCount as string, formColor) -- 返回包含faceCount和formColor的数组
)

-- 收集场景对象的数据
fn collectSceneObjectsData = (
    for obj in objects do (
		if classOf obj == Editable_Poly then (
			-- 计算UV通道数量和formColor
			local numUVChannels = countUVChannels obj
			-- 检测是否存在重叠顶点
			local hasOverlaps = detectOverlappingVertices obj
			-- 计算对象的材质数量	
			local numMaterials = countObjectMaterials obj
			-- 检查对象的UV坐标是否都在第一象限
			local uvsInFirst = checkAllUVsInFirstQuadrant obj
			-- 获取对象的面数量
			local faceCount = getObjectFaceCount obj
			-- 将对象信息添加到全局数组中
			append sceneObjectsData #(obj.name, numUVChannels as string, numMaterials as string, hasOverlaps, uvsInFirst, faceCount as string)
		)
    ) 
)

-- 执行收集场景对象数据的函数
collectSceneObjectsData()

-- 输出收集到的对象信息
for objData in sceneObjectsData do
(
    format "Object Name: %\n" objData[1]
    format "UV Channels: %\n" objData[2]
    format "Materials Count: %\n" objData[3]
    format "Has Overlapping Vertices: %\n" objData[4]
    format "All UVs in First Quadrant: %\n" objData[5]
    format "Face Count: %\n" objData[6]
    format "--------------------------------\n"
)
