import { common } from '@kit.AbilityKit';
import { promptAction, router } from '@kit.ArkUI';
import { collectUniqueCategoryNames, createEmptyNote, generateNoteId, Note } from '../model/Note';
import { NoteStore } from '../store/NoteStore';

@Entry
@Component
struct NoteEditPage {
  @State note: Note = createEmptyNote();
  @State isNew: boolean = true;
  @State categorySuggestions: string[] = [];
  private store: NoteStore = NoteStore.getInstance();

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object> | undefined;
    const noteId = params && params['noteId'] !== undefined ? `${params['noteId']}` : '';
    void this.loadCategorySuggestions();
    if (noteId.length > 0) {
      this.isNew = false;
      void this.loadNote(noteId);
    } else {
      this.isNew = true;
      this.note = createEmptyNote();
    }
  }

  private async loadCategorySuggestions(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    const all = await this.store.loadAll();
    this.categorySuggestions = collectUniqueCategoryNames(all);
  }

  private async loadNote(noteId: string): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    const all = await this.store.loadAll();
    const found = all.find((n: Note) => n.id === noteId);
    if (found) {
      this.note = {
        id: found.id,
        title: found.title,
        content: found.content,
        category: found.category,
        updatedAt: found.updatedAt
      };
    } else {
      promptAction.showToast({ message: '未找到该记事' });
      router.back();
    }
    this.categorySuggestions = collectUniqueCategoryNames(all);
  }

  private async persistNotes(notes: Note[]): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    await this.store.saveAll(notes);
  }

  private resolveTitle(): string {
    const trimmed = this.note.title.trim();
    return trimmed.length > 0 ? trimmed : '无标题';
  }

  private resolveCategory(): string {
    return this.note.category.trim();
  }

  private pickCategory(name: string): void {
    this.note = {
      id: this.note.id,
      title: this.note.title,
      content: this.note.content,
      category: name,
      updatedAt: this.note.updatedAt
    };
  }

  private async onSave(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    const all = await this.store.loadAll();
    const now = Date.now();
    let next: Note[] = [];
    if (this.isNew || this.note.id.length === 0) {
      const id = generateNoteId();
      const created: Note = {
        id: id,
        title: this.resolveTitle(),
        content: this.note.content,
        category: this.resolveCategory(),
        updatedAt: now
      };
      next = [created].concat(all);
    } else {
      next = all.map((n: Note) => {
        if (n.id !== this.note.id) {
          return n;
        }
        return {
          id: n.id,
          title: this.resolveTitle(),
          content: this.note.content,
          category: this.resolveCategory(),
          updatedAt: now
        };
      });
    }
    await this.persistNotes(next);
    promptAction.showToast({ message: '已保存' });
    router.back();
  }

  private confirmDelete(): void {
    promptAction.showDialog({
      title: '删除记事',
      message: '确定要删除这条记事吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#E84026' }
      ]
    }).then((res) => {
      if (res.index === 1) {
        void this.doDelete();
      }
    }).catch(() => {
    });
  }

  private async doDelete(): Promise<void> {
    if (this.isNew || this.note.id.length === 0) {
      router.back();
      return;
    }
    const ctx = getContext(this) as common.UIAbilityContext;
    await this.store.init(ctx);
    const all = await this.store.loadAll();
    const next = all.filter((n: Note) => n.id !== this.note.id);
    await this.persistNotes(next);
    promptAction.showToast({ message: '已删除' });
    router.back();
  }

  @Builder
  FieldLabel(text: ResourceStr) {
    Text(text)
      .fontSize(12)
      .fontColor($r('app.color.subtitle'))
      .fontWeight(FontWeight.Medium)
      .letterSpacing(0.6)
      .margin({ bottom: 8 })
      .alignSelf(ItemAlign.Start)
  }

  build() {
    Column() {
      Column() {
        Row() {
          Button($r('app.string.back'))
            .type(ButtonType.Normal)
            .fontSize(15)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.subtitle'))
            .onClick(() => {
              router.back();
            })
          Text(this.isNew ? $r('app.string.new_note') : $r('app.string.edit_note'))
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.title_text'))
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button({ type: ButtonType.Capsule }) {
            Text($r('app.string.save'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .height(34)
          .padding({ left: 18, right: 18 })
          .backgroundColor($r('app.color.primary'))
          .shadow({
            radius: 10,
            color: '#3346E540',
            offsetX: 0,
            offsetY: 3
          })
          .onClick(() => {
            void this.onSave();
          })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })

        Divider()
          .strokeWidth(0.5)
          .color($r('app.color.border_subtle'))
      }
      .width('100%')
      .backgroundColor($r('app.color.card_background'))
      .shadow({
        radius: 16,
        color: '#0F0F172A',
        offsetX: 0,
        offsetY: 6
      })

      Scroll() {
        Column() {
          Column() {
            this.FieldLabel($r('app.string.label_title'))
            TextInput({ text: this.note.title, placeholder: $r('app.string.title_hint') })
              .width('100%')
              .height(48)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.title_text'))
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_subtle') })
              .borderRadius($r('app.float.radius_input'))
              .padding({ left: 14, right: 14 })
              .onChange((v: string) => {
                this.note = {
                  id: this.note.id,
                  title: v,
                  content: this.note.content,
                  category: this.note.category,
                  updatedAt: this.note.updatedAt
                };
              })

            this.FieldLabel($r('app.string.label_category'))
            TextInput({ text: this.note.category, placeholder: $r('app.string.category_hint') })
              .width('100%')
              .height(46)
              .fontSize(15)
              .fontColor($r('app.color.title_text'))
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_subtle') })
              .borderRadius($r('app.float.radius_input'))
              .padding({ left: 14, right: 14 })
              .margin({ top: 0 })
              .onChange((v: string) => {
                this.note = {
                  id: this.note.id,
                  title: this.note.title,
                  content: this.note.content,
                  category: v,
                  updatedAt: this.note.updatedAt
                };
              })

            if (this.categorySuggestions.length > 0) {
              Column() {
                Text($r('app.string.quick_category'))
                  .fontSize(12)
                  .fontColor($r('app.color.subtitle'))
                  .alignSelf(ItemAlign.Start)
                  .margin({ top: 14, bottom: 10 })
                List({ space: 8 }) {
                  ForEach(this.categorySuggestions, (name: string) => {
                    ListItem() {
                      Button(name)
                        .type(ButtonType.Capsule)
                        .height(32)
                        .fontSize(12)
                        .fontWeight(FontWeight.Medium)
                        .padding({ left: 14, right: 14 })
                        .backgroundColor($r('app.color.chip_background'))
                        .fontColor($r('app.color.primary'))
                        .border({ width: 1, color: $r('app.color.accent_line') })
                        .onClick(() => {
                          this.pickCategory(name);
                        })
                    }
                  }, (name: string) => name)
                }
                .listDirection(Axis.Horizontal)
                .height(38)
                .width('100%')
                .scrollBar(BarState.Off)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .padding(18)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius($r('app.float.radius_card'))
          .border({ width: 1, color: $r('app.color.border_subtle') })
          .shadow({
            radius: 18,
            color: '#100F172A',
            offsetX: 0,
            offsetY: 6
          })

          Column() {
            this.FieldLabel($r('app.string.label_content'))
            TextArea({ text: this.note.content, placeholder: $r('app.string.content_hint') })
              .width('100%')
              .constraintSize({ minHeight: 220 })
              .fontSize(16)
              .fontColor($r('app.color.title_text'))
              .lineHeight(24)
              .backgroundColor($r('app.color.input_background'))
              .border({ width: 1, color: $r('app.color.border_subtle') })
              .borderRadius($r('app.float.radius_input'))
              .padding(14)
              .onChange((v: string) => {
                this.note = {
                  id: this.note.id,
                  title: this.note.title,
                  content: v,
                  category: this.note.category,
                  updatedAt: this.note.updatedAt
                };
              })
          }
          .width('100%')
          .padding(18)
          .margin({ top: 14 })
          .backgroundColor($r('app.color.card_background'))
          .borderRadius($r('app.float.radius_card'))
          .border({ width: 1, color: $r('app.color.border_subtle') })
          .shadow({
            radius: 18,
            color: '#100F172A',
            offsetX: 0,
            offsetY: 6
          })

          if (!this.isNew && this.note.id.length > 0) {
            Button($r('app.string.delete'))
              .width('100%')
              .height(48)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.danger'))
              .backgroundColor(Color.Transparent)
              .border({ width: 1, color: $r('app.color.danger') })
              .borderRadius($r('app.float.radius_input'))
              .margin({ top: 20, bottom: 28 })
              .onClick(() => {
                this.confirmDelete();
              })
          } else {
            Column().height(20)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      angle: 165,
      colors: [
        [$r('app.color.gradient_top'), 0.0],
        [$r('app.color.gradient_mid'), 0.45],
        [$r('app.color.gradient_bottom'), 1.0]
      ]
    })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}
