try (destroydialog sceneDataViewRollout) catch ()

rollout sceneDataViewRollout "Scene Objects Data View" width:700 height:360 (
    dotNetControl dgvSceneObjects "System.Windows.Forms.DataGridView" width:680 height:280 pos:[10,10]
    button btnRefresh "Refresh" width:150 height:24 pos:[10,295]

    -- 函数：计算UV通道数
    fn countUVChannels obj = (
        local numChannels = 0
        if classOf obj == Editable_Poly then (
            for i = 1 to 99 do (
                if polyOp.getMapSupport obj i do (
                    numChannels += 1
                )
            )
        )
        numChannels
    )

    -- 函数：检测是否有重叠顶点
    fn detectOverlappingVertices obj threshold:0.001 = (
        local hasOverlapping = false
        if classOf obj == Editable_Poly then (
            local numVerts = polyOp.getNumVerts obj
            for i=1 to numVerts do (
                local vertPosI = polyOp.getVert obj i
                for j=i+1 to numVerts do (
                    local vertPosJ = polyOp.getVert obj j
                    -- 使用长度比较来判断两个顶点是否足够接近
                    if (i != j) and (length (vertPosI - vertPosJ) < threshold) then (
                        -- 检查两个顶点是否共享至少一个面
                        local facesUsingVertI = polyOp.getFacesUsingVert obj i
                        local facesUsingVertJ = polyOp.getFacesUsingVert obj j
                        local commonFaces = facesUsingVertI * facesUsingVertJ

                        -- 如果两个顶点没有共享的面，则认为它们未焊接
                        if commonFaces.numberset == 0 then (
                            hasOverlapping = true
                            exit with hasOverlapping
                        )
                    )
                )
            )
        )
        hasOverlapping
    )

    -- 函数：计算对象的材质数量
    fn countObjectMaterials obj = (
        local mat = obj.material
        if mat != undefined then (
            if classOf mat == MultiMaterial then
                mat.numsubs
            else
                1
        ) else (
            0
        )
    )

    -- 函数：检查所有UV是否在第一象限
    fn checkAllUVsInFirstQuadrant obj = (
        local allChannelsInFirstQuadrant = true
        local numChannels = countUVChannels obj

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

        allChannelsInFirstQuadrant
    )

    -- 函数：获取对象的面数
	fn getObjectFaceCount obj = (
		if classOf obj == Editable_Poly then (
			polyOp.getNumFaces obj
		) else (
			tempObj = convertToPoly (copy obj)
			faceCount = polyOp.getNumFaces tempObj
			delete tempObj
			faceCount
		)
	)

    
    -- 函数：将bool值转换为字符串
    fn boolToString yesNo = if yesNo then "Yes" else "No"

    -- 函数：收集场景对象数据
    fn collectSceneObjectsData = (
        local objectsData = #()
        for obj in objects do (
            local numUVChannels = countUVChannels obj
            local numMaterials = countObjectMaterials obj
            local hasOverlaps = detectOverlappingVertices obj
            local uvsInFirst = checkAllUVsInFirstQuadrant obj
            append objectsData #(obj.name, numUVChannels as string, numMaterials as string, boolToString hasOverlaps, boolToString uvsInFirst)
        ) 
        objectsData
    )
    
    -- 函数：填充DataGridView
    fn fillDataGridView = (
        local sceneData = collectSceneObjectsData()

        dgvSceneObjects.AllowUserToAddRows = false
        dgvSceneObjects.RowHeadersVisible = false
        
        dgvSceneObjects.Columns.Clear()
        dgvSceneObjects.Rows.Clear()

        -- 创建新的列并设置标题
        local colObjectName = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colObjectName.HeaderText = "名称"
        dgvSceneObjects.Columns.Add(colObjectName)

        local colUVChannelCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colUVChannelCount.HeaderText = "UV数量"
        dgvSceneObjects.Columns.Add(colUVChannelCount)

        local colMaterialCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colMaterialCount.HeaderText = "材质数量"
        dgvSceneObjects.Columns.Add(colMaterialCount)

        local colOverlappingVerts = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colOverlappingVerts.HeaderText = "重合点"
        dgvSceneObjects.Columns.Add(colOverlappingVerts)

        local colUVsFirstQuadrant = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colUVsFirstQuadrant.HeaderText = "UV1象限"
        dgvSceneObjects.Columns.Add(colUVsFirstQuadrant)
        
        local colFaceCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colFaceCount.HeaderText = "面数"
        dgvSceneObjects.Columns.Add(colFaceCount)

        -- 填充DataView的行数据
        for data in sceneData do (
            local rowIndex = dgvSceneObjects.Rows.Add(data)
            local row = dgvSceneObjects.Rows.Item[rowIndex]

            -- 如果UV套数大于2，则将该项显示为红色
            local numUVChannels = try (data[2] as integer) catch 0
            if numUVChannels > 2 do (
                row.Cells.Item[1].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- 如果材质数大于1，则将该项显示为红色
            local numMaterials = try (data[3] as integer) catch 0
            if numMaterials > 1 do (
                row.Cells.Item[2].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- 如果超过1象限，则将该项显示为红色
            local uvsInFirstQuadrant = (data[5] == "Yes")
            if not uvsInFirstQuadrant do (
                row.Cells.Item[4].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- 如果有重合点，则将该项显示为红色
            local hasOverlappingVerts = (data[4] == "Yes")
            if hasOverlappingVerts do (
                row.Cells.Item[3].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )
            
            -- 获取对象的面数并设置到相应单元格
            local obj = getNodeByName data[1]
            local faceCount = getObjectFaceCount obj
            row.Cells.Item[5].Value = faceCount
			
        )	
        
        -- 设置列的自动调整模式为"DisplayedCells"
        dgvSceneObjects.AutoSizeColumnsMode = dgvSceneObjects.AutoSizeColumnsMode.DisplayedCells
		
		-- 禁用DataGridView及其子控件
		dgvSceneObjects.readOnly = true
    )

    on sceneDataViewRollout open do (
        fillDataGridView()
    )

    on btnRefresh pressed do (
        -- 清除旧数据并填充新数据
        dgvSceneObjects.Rows.Clear()
        fillDataGridView()
    )
)

-- 创建并显示对话框
createdialog sceneDataViewRollout 700 360 style:#(#style_titlebar, #style_sysmenu,#style_maximizebox,#style_minimizebox, #style_resizing)
