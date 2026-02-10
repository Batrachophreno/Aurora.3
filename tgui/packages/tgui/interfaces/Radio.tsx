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
  const tunedChannel = RADIO_CHANNELS.find(
    (channel) => channel.freq === data.frequency,
  );
  const channels = map(data.channels, (value, key) => ({
    name: key,
    status: !!value,
  }));
  // Calculate window height
  let height = 133;
  if (channels.length > 0) {
    height += channels.length * 25 + 8;
  } else if (data.subspace) {
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
                  {(data.freqlock && (
                    <Box inline color="light-gray">
                      {`${toFixed(data.frequency / 10, 1)} kHz`}
                    </Box>
                  )) || (
                    <Slider
                      value={data.frequency / 10}
                      animated
                      tickWhileDragging
                      unit="kHz"
                      step={0.2}
                      stepPixelSize={10}
                      minValue={data.minFrequency / 10}
                      maxValue={data.maxFrequency / 10}
                      format={(value) => toFixed(value, 1)}
                      onChange={(value) =>
                        act('frequency', {
                          adjust: value - data.frequency / 10,
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
                color={data.listening ? 'green' : 'red'}
                icon={data.listening ? 'volume-up' : 'volume-mute'}
                selected={data.listening}
                onClick={() => act('listen')}
              />
              <Button
                textAlign="center"
                width="37px"
                color={data.broadcasting ? 'green' : 'red'}
                icon={data.broadcasting ? 'microphone' : 'microphone-slash'}
                selected={data.broadcasting}
                onClick={() => act('broadcast')}
              />
              {!!data.command && (
                <Button
                  ml={1}
                  icon="bullhorn"
                  selected={data.useCommand}
                  content={`High volume ${data.useCommand ? 'ON' : 'OFF'}`}
                  onClick={() => act('command')}
                />
              )}
            </LabeledList.Item>
            {channels.length > 0 && (
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
                      {!data.freqlock && (
                        <Button
                          icon="walkie-talkie"
                          ml={1}
                          disabled={
                            RADIO_CHANNELS.find((c) => c.name === channel.name)
                              ?.freq === data.frequency
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
