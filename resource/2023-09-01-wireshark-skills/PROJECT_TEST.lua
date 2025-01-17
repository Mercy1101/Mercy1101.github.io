-- 定义协议名称
local p_my_protocol = Proto("project_test", "PROJECT_TEST")

-- 定义协议字段
local f_stx = ProtoField.uint8("PROJECT_TEST.stx", "STX", base.HEX)
local f_data_type = ProtoField.uint8("PROJECT_TEST.data_type", "Data Type", base.HEX)
local f_train_group = ProtoField.string("PROJECT_TEST.train_group", "列车车组号")
local f_train_service = ProtoField.string("PROJECT_TEST.train_service", "服务号")
local f_crew_group = ProtoField.string("PROJECT_TEST.crew_group", "乘务组号")
local f_train_position = ProtoField.uint8("PROJECT_TEST.train_position", "列车位置")
local f_train_running_position = ProtoField.uint8("PROJECT_TEST.train_running_position", "列车运行位置")
local f_track_name = ProtoField.string("PROJECT_TEST.track_name", "轨道名称")
local f_station_id = ProtoField.string("PROJECT_TEST.station_id", "车站 ID")
local f_destination_id = ProtoField.string("PROJECT_TEST.destination_id", "终点车站ID")
local f_destination_code = ProtoField.string("PROJECT_TEST.destination_code", "目的地码")
local f_etx = ProtoField.uint8("PROJECT_TEST.etx", "ETX", base.HEX)
local f_crc = ProtoField.uint16("PROJECT_TEST.crc", "CRC", base.HEX)

p_my_protocol.fields = { f_stx, f_data_type, f_train_group, f_train_service, f_crew_group, f_train_position, f_train_running_position, f_track_name, f_station_id, f_destination_id, f_destination_code, f_etx, f_crc }

-- 解析器函数
function p_my_protocol.dissector(buffer, pinfo, tree)
    -- 跳过以太网、IP 和 TCP 协议头
    local payload_offset = 14 + 20 + 20
    if buffer:len() < payload_offset then
        return
    end

    local payload_buffer = buffer(payload_offset)

    local index = 0
    if payload_buffer:len() < index + 1 then
        return
    end
    local stx = payload_buffer(index, 1)
    index = index + 1
    if payload_buffer:len() < index + 1 then
        return
    end
    local data_type = payload_buffer(index, 1)
    index = index + 1

    -- 设置协议解析信息
    pinfo.cols.protocol:set("PROJECT-TEST")
    pinfo.cols.info:set("PROJECT TEST")

    -- 创建协议树的根节点
    local subtree = tree:add(p_my_protocol, payload_buffer())
    -- local subtree = tree:add(p_my_protocol, payload_buffer())
    subtree:add(f_stx, stx)
    subtree:add(f_data_type, data_type)

    -- 循环处理重复的字段
    while index < payload_buffer:len() - 4 do
        if payload_buffer:len() < index + 3 then
            return
        end
        local train_group = payload_buffer(index, 3)
        index = index + 3
        if payload_buffer:len() < index + 3 then
            return
        end
        local train_service = payload_buffer(index, 3)
        index = index + 3
        if payload_buffer:len() < index + 3 then
            return
        end
        local crew_group = payload_buffer(index, 3)
        index = index + 3
        if payload_buffer:len() < index + 1 then
            return
        end
        local train_position = payload_buffer(index, 1)
        index = index + 1
        if payload_buffer:len() < index + 1 then
            return
        end
        local train_running_position = payload_buffer(index, 1)
        index = index + 1
        if payload_buffer:len() < index + 10 then
            return
        end
        local track_name = payload_buffer(index, 10)
        index = index + 10
        if payload_buffer:len() < index + 3 then
            return
        end
        local station_id = payload_buffer(index, 3)
        index = index + 3
        if payload_buffer:len() < index + 3 then
            return
        end
        local destination_id = payload_buffer(index, 3)
        index = index + 3
        if payload_buffer:len() < index + 3 then
            return
        end
        local destination_code = payload_buffer(index, 3)
        index = index + 3

        local repeat_subtree = subtree:add("Repeated Fields")
        repeat_subtree:add(f_train_group, train_group:string())
        repeat_subtree:add(f_train_service, train_service:string())
        repeat_subtree:add(f_crew_group, crew_group:string())
        repeat_subtree:add(f_train_position, train_position)
        repeat_subtree:add(f_train_running_position, train_running_position)
        repeat_subtree:add(f_track_name, track_name:string())
        repeat_subtree:add(f_station_id, station_id:string())
        repeat_subtree:add(f_destination_id, destination_id:string())
        repeat_subtree:add(f_destination_code, destination_code:string())
    end

    if payload_buffer:len() < index + 1 then
        return
    end
    local etx = payload_buffer(index, 1)
    index = index + 1
    if payload_buffer:len() < index + 2 then
        return
    end
    local crc = payload_buffer(index, 2)

    subtree:add(f_etx, etx)
    subtree:add(f_crc, crc)
end

-- 注册协议和解析器
local tcp_dissector_table = DissectorTable.get("tcp.port")
tcp_dissector_table:add(40123, p_my_protocol)