import { BooleanLike, classes } from '../../common/react';
import { useBackend } from '../backend';
import { Button, ByondUi, NoticeBox, Section, Stack } from '../components';
import { NtosWindow } from '../layouts';

type Data = {
  activeCamera: Camera & { status: BooleanLike };
  cameras: Camera[];
  can_spy: BooleanLike;
  mapRef: string;
  currentNetwork: string;
  allNetworks: string[];
};

type Camera = {
  name: string;
  deact: BooleanLike; // deactivated
  camera: string; // ref
  x: number;
  y: number;
  z: number;
};

/**
 * Returns previous and next camera names relative to the currently
 * active camera.
 */
const prevNextCamera = (
  cameras: Camera[],
  activeCamera: Camera & { status: BooleanLike },
) => {
  if (!activeCamera || cameras.length < 2) {
    return [];
  }

  const index = cameras.findIndex(
    (camera) => camera.name === activeCamera.name,
  );

  switch (index) {
    case -1: // Current camera is not in the list
      return [cameras[cameras.length - 1].name, cameras[0].name];

    case 0: // First camera
      if (cameras.length === 2) return [cameras[1].name, cameras[1].name]; // Only two

      return [cameras[cameras.length - 1].name, cameras[index + 1].name];

    case cameras.length - 1: // Last camera
      if (cameras.length === 2) return [cameras[0].name, cameras[0].name];

      return [cameras[index - 1].name, cameras[0].name];

    default:
      // Middle camera
      return [cameras[index - 1].name, cameras[index + 1].name];
  }
};

export const CameraMonitoring = (props, context) => {
  return (
    <NtosWindow width={850} height={708}>
      <NtosWindow.Content>
        <CameraContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const CameraContent = (props, context) => {
  const { act, data } = useBackend<Data>(context);

  return (
    <Stack fill>
      <Stack.Item grow>
        Stack 1
        <CameraSelector />
      </Stack.Item>
      <Stack.Item grow={3}>
        Stack 3
        <CameraControls />
      </Stack.Item>
    </Stack>
  );
};

export const CameraSelector = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { activeCamera } = data;

  return (
    <Stack fill vertical>
      <Stack.Item grow>
        <Section fill scrollable>
          {data.cameras.map((camera) => (
            // We're not using the component here because performance
            // would be absolutely abysmal (50+ ms for each re-render).
            <div
              key={camera.name}
              title={camera.name}
              className={classes([
                'Button',
                'Button--fluid',
                'Button--color--transparent',
                'Button--ellipsis',
                activeCamera?.name === camera.name
                  ? 'Button--selected'
                  : 'candystripe',
              ])}
              onClick={() =>
                act('switch_camera', {
                  name: camera.name,
                })
              }
            >
              {camera.name}
            </div>
          ))}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const CameraControls = (props, context) => {
  const { act, data } = useBackend<Data>(context);
  const { activeCamera, can_spy, mapRef } = data;

  return (
    <Section fill>
      <Stack fill vertical>
        <Stack.Item>
          <Stack fill>
            <Stack.Item grow>
              {activeCamera?.status ? (
                <NoticeBox info>{activeCamera.name}</NoticeBox>
              ) : (
                <NoticeBox danger>No input signal</NoticeBox>
              )}
            </Stack.Item>

            <Stack.Item>
              <Button
                icon="chevron-left"
                onClick={() =>
                  act('switch_camera', {
                    name: 'filler_prev',
                  })
                }
              />
            </Stack.Item>

            <Stack.Item>
              <Button
                icon="chevron-right"
                onClick={() =>
                  act('switch_camera', {
                    name: 'filler_next',
                  })
                }
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
        <Stack.Item grow>
          <ByondUi
            winsetParams={{
              id: mapRef,
              type: 'map',
            }}
            boxProps={{
              height: '100%',
              width: '100%',
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};
