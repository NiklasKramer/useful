-- softcut study 3: cut
--
-- E2 fade time
-- E3 metro time (random cut)

function rerun()
    norns.script.load(norns.state.script)
end

----------------------------------------

file = _path.dust .. "/audio/Loops/perc_loop.wav"
fade_time = 0.00
metro_time = 1.0

positions = { 0, 0, 0, 0 }
g = grid.connect()

TRACKS = 1

durations = { 0, 0, 0, 0 }

function init()
    -- grid
    grid_dirty = true
    softcut.buffer_clear() -- Clear the buffer before loading the new file
    get_duration(file)
    -- softcut

    local ch, samples = audio.file_info(file)
    local file_duration = samples / 48000

    for i = 1, TRACKS, 2 do
        durations[i] = file_duration
        softcut.buffer_read_mono(file, 0, 0, file_duration, i, i)
        softcut.buffer_read_mono(file, 0, 0, file_duration, i+1, i+1)

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

        softcut.phase_quant(i, 0.125)
        --
    end

    softcut.event_phase(update_positions)
    softcut.poll_start_phase()


    --m:start()
end

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
        g:led(positions[i], i * 2, 15)
    end
    g:refresh()
end

function redraw()
    screen.clear()
    screen.move(10, 20)
    screen.line_rel(positions[1] * 8, 0)
    screen.move(40, 20)
    screen.line_rel(positions[2] * 8, 0)
    screen.move(70, 20)
    screen.line_rel(positions[3] * 8, 0)
    screen.move(100, 20)
    screen.line_rel(positions[4] * 8, 0)
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

function update_positions(i, pos)
    normalized_position = (pos) / durations[i]
    positions[i] = math.floor(normalized_position * 8) + 1
    print("positioni:" .. positions[i])
    redraw()
    grid_dirty = true
    redraw_grid()
end

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