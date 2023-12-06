try (destroydialog sceneDataViewRollout) catch ()

rollout sceneDataViewRollout "Scene Objects Data View" width:700 height:360 (
    dotNetControl dgvSceneObjects "System.Windows.Forms.DataGridView" width:680 height:280 pos:[10,10]
    button btnRefresh "Refresh" width:150 height:24 pos:[10,295]

    -- ����������UVͨ����
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

    -- ����������Ƿ����ص�����
    fn detectOverlappingVertices obj threshold:0.001 = (
        local hasOverlapping = false
        if classOf obj == Editable_Poly then (
            local numVerts = polyOp.getNumVerts obj
            for i=1 to numVerts do (
                local vertPosI = polyOp.getVert obj i
                for j=i+1 to numVerts do (
                    local vertPosJ = polyOp.getVert obj j
                    -- ʹ�ó��ȱȽ����ж����������Ƿ��㹻�ӽ�
                    if (i != j) and (length (vertPosI - vertPosJ) < threshold) then (
                        -- ������������Ƿ�������һ����
                        local facesUsingVertI = polyOp.getFacesUsingVert obj i
                        local facesUsingVertJ = polyOp.getFacesUsingVert obj j
                        local commonFaces = facesUsingVertI * facesUsingVertJ

                        -- �����������û�й������棬����Ϊ����δ����
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

    -- �������������Ĳ�������
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

    -- �������������UV�Ƿ��ڵ�һ����
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

    -- ��������ȡ���������
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

    
    -- ��������boolֵת��Ϊ�ַ���
    fn boolToString yesNo = if yesNo then "Yes" else "No"

    -- �������ռ�������������
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
    
    -- ���������DataGridView
    fn fillDataGridView = (
        local sceneData = collectSceneObjectsData()

        dgvSceneObjects.AllowUserToAddRows = false
        dgvSceneObjects.RowHeadersVisible = false
        
        dgvSceneObjects.Columns.Clear()
        dgvSceneObjects.Rows.Clear()

        -- �����µ��в����ñ���
        local colObjectName = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colObjectName.HeaderText = "����"
        dgvSceneObjects.Columns.Add(colObjectName)

        local colUVChannelCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colUVChannelCount.HeaderText = "UV����"
        dgvSceneObjects.Columns.Add(colUVChannelCount)

        local colMaterialCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colMaterialCount.HeaderText = "��������"
        dgvSceneObjects.Columns.Add(colMaterialCount)

        local colOverlappingVerts = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colOverlappingVerts.HeaderText = "�غϵ�"
        dgvSceneObjects.Columns.Add(colOverlappingVerts)

        local colUVsFirstQuadrant = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colUVsFirstQuadrant.HeaderText = "UV1����"
        dgvSceneObjects.Columns.Add(colUVsFirstQuadrant)
        
        local colFaceCount = dotNetObject "System.Windows.Forms.DataGridViewTextBoxColumn"
        colFaceCount.HeaderText = "����"
        dgvSceneObjects.Columns.Add(colFaceCount)

        -- ���DataView��������
        for data in sceneData do (
            local rowIndex = dgvSceneObjects.Rows.Add(data)
            local row = dgvSceneObjects.Rows.Item[rowIndex]

            -- ���UV��������2���򽫸�����ʾΪ��ɫ
            local numUVChannels = try (data[2] as integer) catch 0
            if numUVChannels > 2 do (
                row.Cells.Item[1].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- �������������1���򽫸�����ʾΪ��ɫ
            local numMaterials = try (data[3] as integer) catch 0
            if numMaterials > 1 do (
                row.Cells.Item[2].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- �������1���ޣ��򽫸�����ʾΪ��ɫ
            local uvsInFirstQuadrant = (data[5] == "Yes")
            if not uvsInFirstQuadrant do (
                row.Cells.Item[4].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )

            -- ������غϵ㣬�򽫸�����ʾΪ��ɫ
            local hasOverlappingVerts = (data[4] == "Yes")
            if hasOverlappingVerts do (
                row.Cells.Item[3].Style.BackColor = (dotNetClass "System.Drawing.Color").FromName("Red")
            )
            
            -- ��ȡ��������������õ���Ӧ��Ԫ��
            local obj = getNodeByName data[1]
            local faceCount = getObjectFaceCount obj
            row.Cells.Item[5].Value = faceCount
			
        )	
        
        -- �����е��Զ�����ģʽΪ"DisplayedCells"
        dgvSceneObjects.AutoSizeColumnsMode = dgvSceneObjects.AutoSizeColumnsMode.DisplayedCells
		
		-- ����DataGridView�����ӿؼ�
		dgvSceneObjects.readOnly = true
    )

    on sceneDataViewRollout open do (
        fillDataGridView()
    )

    on btnRefresh pressed do (
        -- ��������ݲ����������
        dgvSceneObjects.Rows.Clear()
        fillDataGridView()
    )
)

-- ��������ʾ�Ի���
createdialog sceneDataViewRollout 700 360 style:#(#style_titlebar, #style_sysmenu,#style_maximizebox,#style_minimizebox, #style_resizing)