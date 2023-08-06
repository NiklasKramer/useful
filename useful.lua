-- softcut study
--
-- E2 fade time
-- E3 metro time (random cut)

function rerun()
    norns.script.load(norns.state.script)
end

----------------------------------------
g = grid.connect()
a = arc.connect()

--------- CONSTANTS -----------------------
files = { _path.dust .. "/audio/joda_samples/chakcha1.wav",
          _path.dust .. "/audio/joda_samples/korikito1.wav",
          _path.dust .. "/audio/joda_samples/lotus_notee.wav",
}

TRACKS = 3
SAMPLE_RATE = 48000

blink_state = false
shift = false
blink_position = { x = 1, y = 1 }

fade_time = 0.00
metro_time = 1.0

speed_list = { 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0 }
speed_step = 3
reverse = 1
duration = 8
position = 0
arc_position = 0
is_playing = 0
dirty_grid = false
dirty_arc = false

track_infos = {}
for i = 1, 3 do
    start_in_buffer = (i - 1) * duration
    track_infos[i] = {
        speedlist = speed_list,
        speed_step = speed_step,
        reverse = reverse,
        duration = duration,
        is_playing = is_playing,
        is_recording = 0,
        position = position,
        arc_position = arc_position,
        momentary = { false, false, false, false },
        loop_storage = { { start = 0, length = 0 },
                         { start = 0, length = 0 },
                         { start = 0, length = 0 },
                         { start = 0, length = 0 } },
        start_in_buffer = start_in_buffer
    }
end

------- ARC -------
function redraw_arc()
    if dirty_arc then
        a:all(0)
        for i = 1, TRACKS do
            a:led(i, track_infos[i].arc_position, 2)
            a:led(i, track_infos[i].arc_position + 1, 15)
            a:led(i, track_infos[i].arc_position + 2, 2)
        end
        a:refresh()
    end
end

------- GRID -------
function redraw_grid()
    if dirty_grid then
        g:all(0)
        -- show loop presets
        for i = 1, 4 do
            for j = 1, TRACKS do
                g:led(4 + i, j * 2 - 1, 15)
            end
        end
        -- show current positions
        for i = 1, TRACKS do
            g:led(track_infos[i].position, i * 2, 15)
        end
        -- toggle play, reverse, speed down, speed up
        for i = 1, TRACKS do
            for j = 1, 4 do
                if track_infos[i].momentary[j] then
                    g:led(j, i * 2 - 1, 15)
                end
            end
        end
        if shift then
            g:led(8, 8, 15)
        end
        g:refresh()
    end
end

function g.key(x, y, z)
    print_track_infos()

    selected_track = math.floor(y / 2) + 1
    -- momentary
    if (get_is_control_row(y)) then
        for i = 1, 4 do
            if (x == i) then
                track_infos[math.floor(y / 2) + 1].momentary[i] = z == 1 and true or false
            end
        end
    end
    -- toggle shift
    if (x == 8 and y == 8) then
        shift = z == 1 and true or false
    end

    --
    if z == 1 then
        if get_is_control_row(y) then
            selected_track = math.floor(y / 2) + 1
            -- toggle record
            if x == 1 then
                track_infos[selected_track].is_recording = 1 - track_infos[selected_track].is_recording

                softcut.rec(y, track_infos[selected_track].is_recording)
                softcut.rec(y + 1, track_infos[selected_track].is_recording)

                softcut.play(y, track_infos[selected_track].is_playing)
                softcut.play(y + 1, track_infos[selected_track].is_playing)

            end
            -- toggle reverse
            if x == 2 then
                print(y)
                track_infos[selected_track].reverse = track_infos[selected_track].reverse == 1 and -1 or 1
                softcut.rate(y, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
                softcut.rate(y + 1, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
            end
            -- set Tempo
            if x == 3 then
                if (track_infos[selected_track].speed_step > 1) then
                    track_infos[selected_track].speed_step = track_infos[selected_track].speed_step - 1

                    softcut.rate(y, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
                    softcut.rate(y + 1, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
                end
            end
            if x == 4 then
                if (track_infos[selected_track].speed_step < #speed_list) then
                    track_infos[selected_track].speed_step = track_infos[selected_track].speed_step + 1
                    softcut.rate(y, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
                    softcut.rate(y + 1, speed_list[track_infos[selected_track].speed_step] * track_infos[selected_track].reverse)
                end
            end
            -- set loop 1
            if x == 5 then
                -- set softcut to loop 1
                softcut.loop_start(y, track_infos[selected_track].loop_storage[1].start)
                softcut.loop_start(y + 1, track_infos[selected_track].loop_storage[1].start)

                softcut.loop_end(y, track_infos[selected_track].loop_storage[1].start + track_infos[selected_track].loop_storage[1].length)
                softcut.loop_end(y + 1, track_infos[selected_track].loop_storage[1].start + track_infos[selected_track].loop_storage[1].length)
            end
            -- set loop 2
            if x == 6 then
                -- set softcut to loop 2
                softcut.loop_start(y, track_infos[selected_track].loop_storage[2].start)
                softcut.loop_start(y + 1, track_infos[selected_track].loop_storage[2].start)

                softcut.loop_end(y, track_infos[selected_track].loop_storage[2].start + track_infos[selected_track].loop_storage[2].length)
                softcut.loop_end(y + 1, track_infos[selected_track].loop_storage[2].start + track_infos[selected_track].loop_storage[2].length)
            end
            -- set loop 3
            if x == 7 then
                -- set softcut to loop 3
                softcut.loop_start(y, track_infos[selected_track].loop_storage[3].start)
                softcut.loop_start(y + 1, track_infos[selected_track].loop_storage[3].start)

                softcut.loop_end(y, track_infos[selected_track].loop_storage[3].start + track_infos[selected_track].loop_storage[3].length)
                softcut.loop_end(y + 1, track_infos[selected_track].loop_storage[3].start + track_infos[selected_track].loop_storage[3].length)
            end
            -- set loop 4
            if x == 8 then
                -- set softcut to loop 4
                softcut.loop_start(y, track_infos[selected_track].loop_storage[4].start)
                softcut.loop_start(y + 1, track_infos[selected_track].loop_storage[4].start)

                softcut.loop_end(y, track_infos[selected_track].loop_storage[4].start + track_infos[selected_track].loop_storage[4].length)
                softcut.loop_end(y + 1, track_infos[selected_track].loop_storage[4].start + track_infos[selected_track].loop_storage[4].length)

            end

        end

        if is_buffer_row(y) then
            if not shift then
                print("buffer row")
                buffer = y - 1
                selected_track = math.floor(y / 2)
                print('Buffer ' .. buffer)
                print("selected track " .. selected_track)
                -- cut audio
                track_infos[selected_track].is_playing = 1
                softcut.play(buffer, track_infos[selected_track].is_playing)
                softcut.play(buffer + 1, track_infos[selected_track].is_playing)

                -- set loop start
                softcut.position(buffer, ((x - 1) / 8.0) * track_infos[selected_track].duration)
                softcut.position(buffer + 1, ((x - 1) / 8.0) * track_infos[selected_track].duration)

                -- set loop to full length

                softcut.loop_start(buffer, track_infos[selected_track].start_in_buffer)
                softcut.loop_start(buffer + 1, track_infos[selected_track].start_in_buffer)

                softcut.loop_end(buffer, track_infos[selected_track].start_in_buffer + track_infos[selected_track].duration)
                softcut.loop_end(buffer + 1, track_infos[selected_track].start_in_buffer + track_infos[selected_track].duration)
            else
                print("buffer row")
                buffer = y - 1
                selected_track = math.floor(y / 2)
                track_infos[selected_track].is_playing = 0
                -- cut audio
                softcut.play(buffer, track_infos[selected_track].is_playing)
                softcut.play(buffer + 1, track_infos[selected_track].is_playing)
            end
        end

    end
    dirty_grid = true
    dirty_arc = true

end

----- SCREEN ------
function enc(n, d)
    if n == 2 then
        fade_time = util.clamp(fade_time + d / 100, 0, 1)
        for i = 1, TRACKS do
            softcut.fade_time(i, fade_time)
        end
    elseif n == 3 then
        metro_time = util.clamp(metro_time + d / 8, 0.0125, 4)
        --m.time = metro_time
    end
    redraw()
end

function redraw()
    screen.clear()
    screen.move(10, 20)
    screen.line_rel(track_infos[1].position * 8, 0)
    screen.move(40, 20)
    --screen.line_rel(track_infos[2].position * 8, 0)
    --screen.move(70, 20)
    --screen.line_rel(track_infos[3].position * 8, 0)
    --screen.move(100, 20)
    --screen.line_rel(track_infos[3].position * 8, 0)
    screen.stroke()
    screen.move(10, 40)
    screen.text("fade time:")
    screen.move(118, 40)
    screen.text_right(string.format("%.2f", fade_time))
    screen.move(10, 50)
    screen.text("metro time:")
    screen.move(118, 50)
    screen.text_right(string.format("%.2f", metro_time))
    screen.update()
end

------- METRO -------
function update_positions(i, pos)
    if (pos and i <= #track_infos * 2) then
        if (i % 2 == 1) then
            selected_track = math.floor(i / 2 + 1)
            normalized_position = (pos) / track_infos[selected_track].duration

            track_infos[selected_track].position = math.floor(normalized_position * 8.0) + 1
            track_infos[selected_track].arc_position = math.floor(normalized_position * 64.0) + 1
            --redraw()
            --grid_dirty = true
            dirty_grid = true
            dirty_arc = true
        end
    end
end

------- UTIL -------
function get_duration(file)
    if util.file_exists(file) == true then
        local ch, samples, samplerate = audio.file_info(file)
        local duration = samples / samplerate
        print("loading file: " .. file)
        print("  channels:\t" .. ch)
        print("  samples:\t" .. samples)
        print("  sample rate:\t" .. samplerate .. "hz")
        print("  duration:\t" .. duration .. " sec")
        return duration
    else
        print "read_wav(): file not found"
    end
end

function print_track_infos()
    for i = 1, #track_infos do
        print("Track " .. i .. " info:")
        print("Speed Step: " .. track_infos[i].speed_step)
        print("Reverse: " .. track_infos[i].reverse)
        print("Duration: " .. track_infos[i].duration)
        print("Is Playing: " .. track_infos[i].is_playing)
        print("Is Recording: " .. track_infos[i].is_recording)
        print("Position: " .. track_infos[i].position)
        print("Arc Position: " .. track_infos[i].arc_position)
        for j = 1, 4 do
            print("Loop " .. j .. " start: " .. track_infos[i].loop_storage[j].start)
            print("Loop " .. j .. " length: " .. track_infos[i].loop_storage[j].length)
        end
        print("---------")
    end
end

function get_is_control_row(y)

    return y <= 6 and y == 1 or y == 3 or y == 5
end

function is_buffer_row(y)

    print("y: " .. y)
    return y == 2 or y == 4 or y == 6
end
------- INIT -------
function init()
    metro.free_all()
    for i = 1, TRACKS do
        --local ch, samples = audio.file_info(files[i])
        --local file_duration = samples / SAMPLE_RATE
        --track_infos[i].duration = file_duration
        start = 0
        length = track_infos[i].duration / 4.0 -- define length
        for j = 1, 4 do
            track_infos[i].loop_storage[j].start = start + length * (j - 1)
            track_infos[i].loop_storage[j].length = length
        end
    end

    gridredrawtimer = metro.init(function()
        redraw_grid()
    end, 0.02, -1)
    gridredrawtimer:start()
    dirty_grid = true

    arc_redraw_timer = metro.init(function()
        redraw_arc()
    end, 0.02, -1)
    arc_redraw_timer:start()
    dirty_arc = true

    init_softcut()

    redraw_grid()
    redraw_arc()
    redraw()
end

function init_softcut()
    -- check out sync function, softcut.voice_sync function.
    audio.level_adc_cut(1)
    audio.level_adc_cut(2)
    softcut.buffer_clear() -- Clear the buffer before loading the new file


    total_duration = 0
    for i = 1, TRACKS do
        stereo_left = i * 2 - 1
        stereo_right = i * 2

        softcut.level_input_cut(1, stereo_left, 1.0)
        softcut.level_input_cut(2, stereo_right, 1.0)

        softcut.rec_level(stereo_left, 1.0)
        softcut.rec_level(stereo_right, 1.0)

        softcut.enable(stereo_left, 1)
        softcut.enable(stereo_right, 1)

        softcut.buffer(stereo_left, stereo_left)
        softcut.buffer(stereo_right, stereo_right)

        softcut.level(stereo_left, 1.0)
        softcut.level(stereo_right, 1.0)

        softcut.pan(stereo_left, -1)
        softcut.pan(stereo_right, 1)

        softcut.rate(stereo_left, 1)
        softcut.rate(stereo_right, 1)

        softcut.voice_sync(stereo_left, stereo_right, 0)

        softcut.loop(stereo_left, 1)
        softcut.loop(stereo_right, 1)

        softcut.fade_time(stereo_left, fade_time)
        softcut.fade_time(stereo_right, fade_time)

        --sum duration of all tracks
        total_duration = total_duration + (track_infos[i].duration)

        print("total duration: " .. total_duration)

        softcut.loop_start(stereo_left, track_infos[i].start_in_buffer)
        softcut.loop_start(stereo_right, track_infos[i].start_in_buffer)

        softcut.loop_end(stereo_left, track_infos[i].start_in_buffer + track_infos[i].duration)
        softcut.loop_end(stereo_right, track_infos[i].start_in_buffer + track_infos[i].duration)

        softcut.position(stereo_left, 0)
        softcut.position(stereo_right, 0)

        softcut.phase_quant(stereo_right, .1)
        softcut.phase_quant(stereo_left, .1)

        softcut.event_phase(update_positions)
        softcut.poll_start_phase()
    end

end
