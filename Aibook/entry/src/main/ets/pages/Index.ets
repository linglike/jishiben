import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import {
  collectUniqueCategoryNames,
  FILTER_ALL,
  FILTER_UNCATEGORIZED,
  Note,
  normalizeCategoryLabel
} from '../model/Note';
import { NoteStore } from '../store/NoteStore';

function formatUpdatedAt(ms: number): string {
  const d = new Date(ms);
  const month = d.getMonth() + 1;
  const day = d.getDate();
  const hour = d.getHours();
  const minute = d.getMinutes();
  const pad = (n: number): string => (n < 10 ? `0${n}` : `${n}`);
  return `${d.getFullYear()}-${pad(month)}-${pad(day)} ${pad(hour)}:${pad(minute)}`;
}

function previewContent(text: string): string {
  const singleLine = text.replace(/\s+/g, ' ').trim();
  if (singleLine.length <= 80) {
    return singleLine;
  }
  return `${singleLine.substring(0, 80)}…`;
}

function hasUncategorized(notes: Note[]): boolean {
  for (let i = 0; i < notes.length; i++) {
    if (notes[i].category.trim().length === 0) {
      return true;
    }
  }
  return false;
}

@Entry
@Component
struct Index {
  @State allNotes: Note[] = [];
  @State displayNotes: Note[] = [];
  @State searchQuery: string = '';
  @State selectedFilter: string = FILTER_ALL;
  @State categoryNames: string[] = [];
  private store: NoteStore = NoteStore.getInstance();

  aboutToAppear(): void {
    void this.refresh();
  }

  onPageShow(): void {
    void this.refresh();
  }

  private applyFilters(): void {
    let list = this.allNotes.slice();
    if (this.selectedFilter === FILTER_UNCATEGORIZED) {
      list = list.filter((n: Note) => n.category.trim().length === 0);
    } else if (this.selectedFilter !== FILTER_ALL) {
      list = list.filter((n: Note) => n.category.trim() === this.selectedFilter);
    }
    const q = this.searchQuery.trim().toLowerCase();
    if (q.length > 0) {
      list = list.filter((n: Note) => {
        return n.title.toLowerCase().includes(q) ||
          n.content.toLowerCase().includes(q) ||
          n.category.trim().toLowerCase().includes(q);
      });
    }
    list.sort((a: Note, b: Note) => b.updatedAt - a.updatedAt);
    this.displayNotes = list;
  }

  private ensureValidFilter(): void {
    if (this.selectedFilter === FILTER_ALL || this.selectedFilter === FILTER_UNCATEGORIZED) {
      return;
    }
    let exists = false;
    for (let i = 0; i < this.allNotes.length; i++) {
      if (this.allNotes[i].category.trim() === this.selectedFilter) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      this.selectedFilter = FILTER_ALL;
    }
    if (this.selectedFilter === FILTER_UNCATEGORIZED && !hasUncategorized(this.allNotes)) {
      this.selectedFilter = FILTER_ALL;
    }
  }

  private async refresh(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    this.allNotes = await this.store.loadAll();
    this.categoryNames = collectUniqueCategoryNames(this.allNotes);
    this.ensureValidFilter();
    this.applyFilters();
  }

  private openNew(): void {
    router.pushUrl({ url: 'pages/NoteEditPage', params: { noteId: '' } }).catch(() => {
    });
  }

  private openEdit(note: Note): void {
    router.pushUrl({ url: 'pages/NoteEditPage', params: { noteId: note.id } }).catch(() => {
    });
  }

  private selectFilter(value: string): void {
    this.selectedFilter = value;
    this.applyFilters();
  }

  @Builder
  CapsuleFilterResource(label: Resource, value: string, selected: boolean) {
    Button(label)
      .type(ButtonType.Capsule)
      .height(34)
      .fontSize(13)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .padding({ left: 16, right: 16 })
      .backgroundColor(selected ? $r('app.color.primary') : $r('app.color.chip_muted'))
      .fontColor(selected ? Color.White : $r('app.color.subtitle'))
      .border({
        width: selected ? 0 : 1,
        color: $r('app.color.border_subtle')
      })
      .onClick(() => {
        this.selectFilter(value);
      })
  }

  @Builder
  CapsuleFilterText(label: string, value: string, selected: boolean) {
    Button(label)
      .type(ButtonType.Capsule)
      .height(34)
      .fontSize(13)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .padding({ left: 16, right: 16 })
      .backgroundColor(selected ? $r('app.color.primary') : $r('app.color.chip_muted'))
      .fontColor(selected ? Color.White : $r('app.color.subtitle'))
      .border({
        width: selected ? 0 : 1,
        color: $r('app.color.border_subtle')
      })
      .onClick(() => {
        this.selectFilter(value);
      })
  }

  @Builder
  EmptyBlock(icon: string, message: ResourceStr) {
    Column() {
      Text(icon)
        .fontSize(48)
        .margin({ bottom: 16 })
        .opacity(0.88)
      Text(message)
        .fontSize(16)
        .fontColor($r('app.color.subtitle'))
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .padding({ left: 36, right: 36 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Column() {
        Row() {
          Column() {
            Text($r('app.string.app_title'))
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.title_text'))
              .letterSpacing(0.3)
            Text($r('app.string.home_subtitle'))
              .fontSize(13)
              .fontColor($r('app.color.subtitle'))
              .margin({ top: 6 })
            Text(`共 ${this.allNotes.length} 条记事`)
              .fontSize(12)
              .fontColor($r('app.color.subtitle'))
              .opacity(0.9)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button({ type: ButtonType.Capsule }) {
            Row({ space: 6 }) {
              Text('＋')
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
              Text($r('app.string.new_note'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
            .padding({ left: 4, right: 4 })
          }
          .height(40)
          .padding({ left: 14, right: 16 })
          .backgroundColor($r('app.color.primary'))
          .shadow({
            radius: 12,
            color: '#3346E540',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            this.openNew();
          })
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)

        Row() {
          Text('⌕')
            .fontSize(18)
            .fontColor($r('app.color.subtitle'))
            .margin({ right: 10 })
          TextInput({ text: this.searchQuery, placeholder: $r('app.string.search_hint') })
            .layoutWeight(1)
            .height(40)
            .fontSize(15)
            .fontColor($r('app.color.title_text'))
            .backgroundColor(Color.Transparent)
            .padding({ left: 0, right: 0 })
            .onChange((v: string) => {
              this.searchQuery = v;
              this.applyFilters();
            })
        }
        .width('100%')
        .padding({ left: 14, right: 14 })
        .margin({ top: 18 })
        .backgroundColor($r('app.color.search_fill'))
        .border({ width: 1, color: $r('app.color.border_subtle') })
        .borderRadius($r('app.float.radius_input'))

        Text($r('app.string.section_filter'))
          .fontSize(12)
          .fontColor($r('app.color.subtitle'))
          .fontWeight(FontWeight.Medium)
          .letterSpacing(1)
          .margin({ top: 20, bottom: 10 })
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 4 })

      List({ space: 10 }) {
        ListItem() {
          this.CapsuleFilterResource($r('app.string.filter_all'), FILTER_ALL, this.selectedFilter === FILTER_ALL)
        }
        if (hasUncategorized(this.allNotes)) {
          ListItem() {
            this.CapsuleFilterResource($r('app.string.uncategorized'), FILTER_UNCATEGORIZED,
              this.selectedFilter === FILTER_UNCATEGORIZED)
          }
        }
        ForEach(this.categoryNames, (name: string) => {
          ListItem() {
            this.CapsuleFilterText(name, name, this.selectedFilter === name)
          }
        }, (name: string) => name)
      }
      .listDirection(Axis.Horizontal)
      .height(44)
      .width('100%')
      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 8 })

      if (this.allNotes.length === 0) {
        this.EmptyBlock('📝', $r('app.string.empty_hint'))
      } else if (this.displayNotes.length === 0) {
        this.EmptyBlock('🔎', $r('app.string.no_match_hint'))
      } else {
        List({ space: 14 }) {
          ForEach(this.displayNotes, (item: Note) => {
            ListItem() {
              Row({ space: 14 }) {
                Column()
                  .width(4)
                  .height(40)
                  .borderRadius(2)
                  .linearGradient({
                    angle: 180,
                    colors: [[$r('app.color.primary'), 0.0], [$r('app.color.primary_dark'), 1.0]]
                  })

                Column() {
                  Row() {
                    Text(item.title.length > 0 ? item.title : '无标题')
                      .fontSize(17)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.title_text'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text(formatUpdatedAt(item.updatedAt))
                      .fontSize(12)
                      .fontColor($r('app.color.subtitle'))
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)

                  Row() {
                    Text(normalizeCategoryLabel(item.category))
                      .fontSize(12)
                      .fontColor($r('app.color.primary'))
                      .backgroundColor($r('app.color.chip_background'))
                      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                      .borderRadius(20)
                  }
                  .margin({ top: 10 })
                  .width('100%')

                  if (item.content.trim().length > 0) {
                    Text(previewContent(item.content))
                      .fontSize(14)
                      .fontColor($r('app.color.subtitle'))
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 10 })
                      .width('100%')
                      .lineHeight(22)
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 16, right: 18, top: 16, bottom: 16 })
              .backgroundColor($r('app.color.card_background'))
              .borderRadius($r('app.float.radius_card'))
              .border({ width: 1, color: $r('app.color.border_subtle') })
              .shadow({
                radius: 20,
                color: '#140F172A',
                offsetX: 0,
                offsetY: 8
              })
              .onClick(() => {
                this.openEdit(item);
              })
            }
          }, (item: Note) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, bottom: 20 })
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 165,
      colors: [
        [$r('app.color.gradient_top'), 0.0],
        [$r('app.color.gradient_mid'), 0.42],
        [$r('app.color.gradient_bottom'), 1.0]
      ]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
