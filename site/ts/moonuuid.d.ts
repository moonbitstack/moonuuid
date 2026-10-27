declare module "moonuuid" {
  export function describe(text: string): string;
  export function make_v1(): string;
  export function make_v3(space: string, name: string): string;
  export function make_v4(): string;
  export function make_v5(space: string, name: string): string;
  export function make_v6(): string;
  export function make_v7(): string;
  export function make_v8(): string;
}
