-- softcut study 3: cut
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
files = { _path.dust .. "/audio/Loops/piano.wav",
          _path.dust .. "/audio/Loops/piano.wav",
          _path.dust .. "/audio/Loops/piano.wav",
          _path.dust .. "/audio/Loops/piano.wav" }

fade_time = 0.00
metro_time = 1.0

speed_list = { 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0 }
speed_step = 3
reverse = 1
duration = 0
position = 0
arc_position = 0
is_playing = 0
momentary = { false, false, false, false }

track_info = { speedlist = speed_list,
               speed_step = speed_step,
               reverse = reverse,
               duration = duration,
               is_playing = is_playing,
               position = position,
               arc_position = arc_position,
               momentary = momentary }

track_infos = { track_info, track_info, track_info }

positions = { 0, 0, 0, 0 }

TRACKS = 1

------- INIT -------
function init()
    -- grid
    grid_dirty = true
    init_softcut()

end

function init_softcut()
    softcut.buffer_clear() -- Clear the buffer before loading the new file
    get_duration(files[1])
    -- softcut

    local ch, samples = audio.file_info(files[1])
    local file_duration = samples / 48000

    for i = 1, TRACKS, 2 do
        track_infos[i].duration = file_duration

        softcut.buffer_read_mono(files[i], 0, 0, file_duration, i, i)
        softcut.buffer_read_mono(files[i], 0, 0, file_duration, i + 1, i + 1)

        softcut.enable(i, 0)
        softcut.enable(i + 1, 0)

        softcut.enable(i, 1)
        softcut.enable(i + 1, 1)

        softcut.buffer(i, 1)
        softcut.buffer(i + 1, 0)

        softcut.level(i, 1.0)
        softcut.level(i + 1, 1.0)

        softcut.pan(i, -1)
        softcut.pan(i + 1, 1)

        softcut.rate(i, 1)
        softcut.rate(i + 1, 1)

        softcut.loop(i, 1)
        softcut.loop(i + 1, 1)

        softcut.fade_time(i, fade_time)
        softcut.fade_time(i + 1, fade_time)

        softcut.loop_start(i, 0)
        softcut.loop_start(i + 1, 0)

        softcut.loop_end(i, file_duration)
        softcut.loop_end(i + 1, file_duration)

        softcut.position(i, 0)
        softcut.position(i + 1, 0)

        softcut.play(i, 1)
        softcut.play(i + 1, 1)

        softcut.phase_quant(i, 0.5)
        --
    end

    softcut.event_phase(update_positions)
    softcut.poll_start_phase()
end

------- ARC -------
function redraw_arc()
    a:all(0)
    for i = 1, TRACKS do
        a:led(i, track_infos[i].arc_position, 2)
        a:led(i, track_infos[i].arc_position + 1, 15)
        a:led(i, track_infos[i].arc_position + 2, 2)


    end
    a:refresh()
end

------- GRID -------
function redraw_grid()
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
    for i = 1, 4 do
        if track_infos[1].momentary[i] then
            -- if the key is held...
            g:led(i, 1, 15) -- turn on that LED!
        end

    end
    g:refresh()
end

function g.key(x, y, z)
    -- momentary
    for i = 1, 4 do
        if (x == i and y == 1) then
            track_infos[1].momentary[i] = z == 1 and true or false
        end
    end

    if z == 1 then
        if y == 1 then
            print("toggle")
            -- toggle play
            if x == 1 then
                track_infos[1].is_playing = 1 - track_infos[1].is_playing
                softcut.play(1, track_infos[1].is_playing)
                softcut.play(2, track_infos[1].is_playing)
            end
            -- set Tempo
            if x == 4 then
                if (track_infos[1].speed_step < #speed_list) then
                    track_infos[1].speed_step = track_infos[1].speed_step + 1
                    softcut.rate(1, speed_list[track_infos[1].speed_step] * reverse)
                    softcut.rate(2, speed_list[track_infos[1].speed_step] * reverse)
                end
            end
            if x == 3 then
                if (track_infos[1].speed_step > 1) then
                    track_infos[1].speed_step = track_infos[1].speed_step - 1
                    softcut.rate(1, speed_list[track_infos[1].speed_step] * reverse)
                    softcut.rate(2, speed_list[track_infos[1].speed_step] * reverse)
                end
            end
            -- set direction
            if x == 2 then
                reverse = reverse * -1
                softcut.rate(1, speed_list[track_infos[1].speed_step] * reverse)
                softcut.rate(2, speed_list[track_infos[1].speed_step] * reverse)
            end
        end
        if y == 2 then
            -- cut audio
            softcut.play(1, 1)
            softcut.play(2, 1)
            -- set loop start
            softcut.position(1, ((x - 1) / 8.0) * track_infos[1].duration)
            softcut.position(2, ((x - 1) / 8.0) * track_infos[1].duration)


        end

    end
    redraw_grid()

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
    screen.line_rel(track_infos[2].position * 8, 0)
    screen.move(70, 20)
    screen.line_rel(track_infos[3].position * 8, 0)
    screen.move(100, 20)
    screen.line_rel(track_infos[3].position * 8, 0)
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
    normalized_position = (pos) / track_infos[i].duration
    track_infos[i].position = math.floor(normalized_position * 8) + 1
    track_infos[i].arc_position = math.floor(normalized_position * 56) + 1
    redraw()
    grid_dirty = true
    redraw_grid()
    redraw_arc()
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