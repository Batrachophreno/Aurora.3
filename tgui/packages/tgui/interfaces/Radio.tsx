import { map } from 'es-toolkit/compat';
import {
  Box,
  Button,
  LabeledList,
  Section,
  Slider,
  Stack,
} from '../components';
import { toFixed } from '../../common/math';
import type { BooleanLike } from '../../common/react';

import { useBackend } from '../backend';
import { RADIO_CHANNELS } from '../constants';
import { Window } from '../layouts';

type RadioData = {
  freqlock: BooleanLike;
  frequency: number;
  minFrequency: number;
  maxFrequency: number;
  listening: BooleanLike;
  broadcasting: BooleanLike;
  command: BooleanLike;
  useCommand: BooleanLike;
  subspace: BooleanLike;
  channels: Record<string, BooleanLike>;
  radio_noises: number;
};

export const Radio = (props, context) => {
  const { act, data } = useBackend<RadioData>(context);
  const {
    freqlock,
    frequency,
    minFrequency,
    maxFrequency,
    listening,
    broadcasting,
    command,
    useCommand,
    subspace,
    radio_noises,
  } = data;
  const tunedChannel = RADIO_CHANNELS.find(
    (channel) => channel.freq === frequency,
  );
  const channels = map(data.channels, (value, key) => ({
    name: key,
    status: !!value,
  }));
  // Calculate window height
  let height = 133;
  if (channels.length > 0) {
    height += channels.length * 25 + 8;
  } else if (subspace) {
    height += 24;
  }
  return (
    <Window width={380} height={height}>
      <Window.Content>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Frequency">
              <Stack fill>
                <Stack.Item>
                  <Button
                    icon="fast-backward"
                    onClick={() =>
                      act('frequency', {
                        adjust: -10,
                      })
                    }
                  />
                  <Button
                    icon="backward"
                    onClick={() =>
                      act('frequency', {
                        adjust: -2,
                      })
                    }
                  />
                </Stack.Item>
                <Stack.Item>
                  {(freqlock && (
                    <Box inline color="light-gray">
                      {`${toFixed(frequency / 10, 1)} kHz`}
                    </Box>
                  )) || (
                    <Slider
                      value={frequency / 10}
                      animated
                      tickWhileDragging
                      unit="kHz"
                      step={0.2}
                      stepPixelSize={10}
                      minValue={minFrequency / 10}
                      maxValue={maxFrequency / 10}
                      format={(value) => toFixed(value, 1)}
                      onChange={(value) =>
                        act('frequency', {
                          adjust: value - frequency / 10,
                        })
                      }
                    />
                  )}
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="forward"
                    onClick={() =>
                      act('frequency', {
                        adjust: 2,
                      })
                    }
                  />
                  <Button
                    icon="fast-forward"
                    onClick={() =>
                      act('frequency', {
                        adjust: 10,
                      })
                    }
                  />
                </Stack.Item>
                <Stack.Item>
                  {tunedChannel && (
                    <Box inline color={tunedChannel.color} ml={2}>
                      [{tunedChannel.name}]
                    </Box>
                  )}
                </Stack.Item>
              </Stack>
            </LabeledList.Item>
            <LabeledList.Item label="Audio">
              <Button
                textAlign="center"
                width="37px"
                icon={listening ? 'volume-up' : 'volume-mute'}
                selected={listening}
                onClick={() => act('listen')}
              />
              <Button
                textAlign="center"
                width="37px"
                icon={broadcasting ? 'microphone' : 'microphone-slash'}
                selected={broadcasting}
                onClick={() => act('broadcast')}
              />
              {!!command && (
                <Button
                  ml={1}
                  icon="bullhorn"
                  selected={useCommand}
                  content={`High volume ${useCommand ? 'ON' : 'OFF'}`}
                  onClick={() => act('command')}
                />
              )}
            </LabeledList.Item>
            {(!!subspace || channels.length > 0) && (
              <LabeledList.Item label="Channels">
                {channels.length === 0 && (
                  <Box inline color="bad">
                    No encryption keys installed.
                  </Box>
                )}
                <Stack vertical>
                  {channels.map((channel) => (
                    <Box key={channel.name}>
                      <Button
                        icon={channel.status ? 'check-square-o' : 'square-o'}
                        selected={channel.status}
                        content={channel.name}
                        onClick={() =>
                          act('channel', {
                            channel: channel.name,
                          })
                        }
                      />
                      {!subspace && !freqlock && (
                        <Button
                          icon="walkie-talkie"
                          ml={1}
                          disabled={
                            RADIO_CHANNELS.find((c) => c.name === channel.name)
                              ?.freq === frequency
                          }
                          onClick={() =>
                            act('tune_to_channel', {
                              channel: channel.name,
                            })
                          }
                        >
                          Tune
                        </Button>
                      )}
                    </Box>
                  ))}
                </Stack>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
